import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_video/stream_video.dart';
import 'package:webroom_client/domain/enums/user_role.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../data/models/room_member_model.dart';
import '../../../data/repositories/room_repository_impl.dart';
import '../../../data/datasources/room_remote_datasource.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/websocket_service.dart';
import '../../../domain/enums/room_status.dart';
import '../../auth/providers/auth_provider.dart';
import 'getstream_provider.dart';

part 'room_session_provider.freezed.dart';

@freezed
abstract class RoomSession with _$RoomSession {
  const factory RoomSession({
    required String roomId,
    required String roomName,
    required RoomStatus status,
    required List<RoomMemberModel> members,
    required String getstreamCallId,
    @Default(false) bool isInCall,
    @Default(false) bool isEnded,
    @Default(false) bool isHost,
    @Default(false) bool isHostDisconnected,
    @Default(0) int hostGraceSeconds,
  }) = _RoomSession;
}

class RoomSessionNotifier extends AsyncNotifier<RoomSession> {
  StreamSubscription? _wsSub;
  StreamSubscription? _callStateSub;
  StreamSubscription? _callEventsSub;
  StreamSubscription? _callConnectionSub;
  String? _roomId;
  bool _isLeaving = false;
  final Set<String> _grantedPermissionUsers = {};

  @override
  Future<RoomSession> build() async {
    ref.onDispose(_cleanup);
    return const RoomSession(
      roomId: '',
      roomName: '',
      status: RoomStatus.inactive,
      members: [],
      getstreamCallId: '',
    );
  }

  /// Fetches room details. Auto-enters the call if the room is live and this user is the host.
  Future<void> loadRoom(String roomId) async {
    // If there's already an active call session for this room, skip the
    // entire join flow.  This prevents duplicate joins when the user
    // navigates back and then re-opens the same room.
    final existingCall = ref.read(activeCallProvider);
    final existingSession = state.value;
    if (existingCall != null &&
        existingSession != null &&
        existingSession.roomId == roomId &&
        existingSession.isInCall) {
      return;
    }

    _roomId = roomId;
    state = const AsyncLoading();

    try {
      print("────────────────────────────────────────────────────────────────");
      print('Loading room session for roomId: $roomId');
      print("────────────────────────────────────────────────────────────────");

      final authState = ref.read(authStateProvider);
      final userId = authState.whenOrNull(authenticated: (user) => user.userId);
      final userRole = authState.whenOrNull(authenticated: (user) => user.role);

      final roomData = await _repo().getRoom(roomId);
      final List<RoomMemberModel> members;

      state = AsyncData(
        RoomSession(
          roomId: roomId,
          roomName: roomData.room.name,
          status: RoomStatus.live,
          members: [],
          getstreamCallId: roomData.room.getstreamCallId,
          isInCall: true,
          isHost: roomData.isHost,
        ),
      );

      // final data = await _repo().joinRoom(_roomId!);
      // final getStreamCallId = data['getstreamCallId'] as String? ?? '';

      if (userRole == UserRole.host) {
        print("-----------------------------------------------------------");
        print('User is host, fetching room details');
        print("-----------------------------------------------------------");

        final members = await _repo().getMembers(roomId);
        state = AsyncData(
          RoomSession(
            roomId: roomId,
            roomName: roomData.room.name,
            status: RoomStatus.live,
            members: members,
            getstreamCallId: roomData.room.getstreamCallId,
            isInCall: true,
            isHost: true,
          ),
        );

        startRoomAndEnter();
      } else {
        print("-----------------------------------------------------------");
        print('User is guest, fetching room details');
        print("-----------------------------------------------------------");
        joinRoomAndEnter();
      }
      return;

      //
      // // Host navigating back to a room they already started — re-enter via getRoom credentials.
      // if (roomData.room.status == RoomStatus.live && roomData.isHost) {
      //   print("-----------------------------------------------------------");
      //   print('Auto-entering live room as host');
      //   print("-----------------------------------------------------------");
      // await _enterCall(getstreamCallId: getStreamCallId, roomId: roomId);
      // }
    } catch (e, st) {
      print("ERROR: $e");
      state = AsyncError(e, st);
    }
  }

  /// Host taps "Start Room" (room must be active).
  Future<void> startRoomAndEnter() async {
    print("-----------------------------------------------------------");
    print('Starting room and entering call');
    print("-----------------------------------------------------------");
    final current = state.value;
    print("-----------------------------------------------------------");
    print("current : ${current.toString()}");
    print("-----------------------------------------------------------");
    if (current == null || _roomId == null) return;

    print("chk 1");

    try {
      print("chk 2");
      final data = await _repo().startRoom(_roomId!);
      print("chk 3");
      final callId =
          data['getstreamCallId'] as String? ?? current.getstreamCallId;

      print("chk 4");
      state = AsyncData(
        current.copyWith(status: RoomStatus.live, getstreamCallId: callId),
      );
      print("chk 5");

      await _enterCall(getstreamCallId: callId, roomId: _roomId!);

      print("chk 6");
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// User taps "Join Room" (room must be live).
  Future<void> joinRoomAndEnter() async {
    final current = state.value;
    if (current == null || _roomId == null) return;

    try {
      await _enterCall(
        getstreamCallId: current.getstreamCallId,
        roomId: _roomId!,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Re-fetches room state (user polling while waiting for host).
  Future<void> refreshRoom() async {
    final roomId = _roomId;
    if (roomId == null) return;
    await loadRoom(roomId);
  }

  /// Deletes the room permanently (host only).
  Future<void> deleteRoom() async {
    final roomId = _roomId;
    if (roomId == null) return;
    await _repo().deleteRoom(roomId);
  }

  /// Refreshes the getstream token via /auth/refresh and reinitializes the SDK.
  Future<void> _refreshAndReinitGetstream() async {
    final storage = ref.read(secureStorageProvider);
    final refreshToken = await storage.read(StorageKeys.refreshToken);
    if (refreshToken == null) throw Exception('No refresh token available');

    final dio = ref.read(dioClientProvider);
    final response = await dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    final newAccessToken = response.data['accessToken'] as String;
    final newRefreshToken = response.data['refreshToken'] as String;
    final newGetstreamToken = response.data['getstreamToken'] as String;
    await storage.write(StorageKeys.accessToken, newAccessToken);
    await storage.write(StorageKeys.refreshToken, newRefreshToken);
    await storage.write(StorageKeys.getstreamToken, newGetstreamToken);

    final authState = ref.read(authStateProvider);
    final userId = authState.whenOrNull(authenticated: (user) => user.userId)!;
    final userName = authState.whenOrNull(authenticated: (user) => user.name)!;
    final userRole = authState.whenOrNull(authenticated: (user) => user.role)!;

    await ref
        .read(getstreamStateProvider.notifier)
        .reinitialize(
          userId: userId,
          userName: userName,
          getstreamToken: newGetstreamToken,
          role: userRole,
        );

    print("getstream SDK reinitialized with fresh token");
  }

  Future<void> _enterCall({
    required String getstreamCallId,
    required String roomId,
  }) async {
    try {
      await _enterCallInner(getstreamCallId: getstreamCallId, roomId: roomId);
    } catch (e) {
      print("_enterCall failed: $e — refreshing getstream token and retrying");
      await _refreshAndReinitGetstream();
      await _enterCallInner(getstreamCallId: getstreamCallId, roomId: roomId);
    }
  }

  Future<void> _enterCallInner({
    required String getstreamCallId,
    required String roomId,
  }) async {
    print("entering calll");
    final current = state.value;
    print("-----------------------------------------------------------");
    print("current state : ${current.toString()}");
    print("-----------------------------------------------------------");
    if (current == null) return;

    final authState = ref.read(authStateProvider);
    final userId = authState.whenOrNull(authenticated: (user) => user.userId);
    final userName = authState.whenOrNull(authenticated: (user) => user.name);
    final userRole = authState.whenOrNull(authenticated: (user) => user.role);
    final token = await ref
        .read(secureStorageProvider)
        .read(StorageKeys.getstreamToken);
    print("────────────────────────────────────────────────────────────────");
    print("userId : ${userId}, userRole: ${userRole.toString()}");
    print("────────────────────────────────────────────────────────────────");

    print("entercall: chk 1");
    // Request microphone permission before touching the audio stack.
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception(
        'Microphone permission is required to join a room. Please grant it in Settings.',
      );
    }
    print("entercall: chk 2");

    // if getstream is not yet initialized then reinitialize it
    if (ref.read(getstreamStateProvider).isInitialized == false) {
      await ref
          .read(getstreamStateProvider.notifier)
          .init(
            userId: userId!,
            userName: userName!,
            getstreamToken: token!,
            role: userRole!,
          );
    }

    // Health-check: queryCalls will fail if the coordinator WS is stale.
    // Throw on failure so the outer _enterCall can catch & retry with a
    // fresh GetStream connection.
    final call_stat = await StreamVideo.instance.queryCalls(
      filterConditions: {'id': getstreamCallId},
    );

    print("-----------------------------------------------------------");
    print("if any old call stat : ${call_stat.toString()}");
    print("-----------------------------------------------------------");

    if (!call_stat.isSuccess) {
      throw Exception('GetStream coordinator not connected: $call_stat');
    }

    final call = StreamVideo.instance.makeCall(
      callType: StreamCallType.audioRoom(),
      id: getstreamCallId,
    );

    print("-----------------------------------------------------------");
    print("call : ${call.toString()}");
    print("-----------------------------------------------------------");

    print("entercall: chk 3");

    final getCallRes = await call.getOrCreate(
      audio: StreamAudioSettings(
        // accessRequestEnabled: true,
        micDefaultOn: false,
      ),
    );

    print("-----------------------------------------------------------");
    print("getCallRes isSuccess : ${getCallRes.isSuccess}");
    print("-----------------------------------------------------------");

    if (!getCallRes.isSuccess) {
      throw Exception('getOrCreate failed: ${getCallRes.toString()}');
    }

    print("entercall: chk 4");

    // If this call was already joined (e.g. stale state from a previous
    // session), leave first so the SFU clears old publisher tracks.
    if (call.state.value.status.isAlreadyJoined) {
      print("stale call detected — leaving before rejoin");
      await call.leave();
    }

    // Host joins with mic on; users join muted (PTT mode).
    final micEnabled = userRole == UserRole.host;
    final connectOptions = CallConnectOptions(
      microphone: micEnabled ? TrackOption.enabled() : TrackOption.disabled(),
    );
    await call
        .join(connectOptions: connectOptions)
        .timeout(const Duration(seconds: 15));

    print("entercall: chk 5");
    print("-----------------------------------------------------------");
    print(
      "post-join call state — backstage: ${call.state.value.isBackstage}, "
      "participants: ${call.state.value.callParticipants.length}, "
      "status: ${call.state.value.status}",
    );
    print("-----------------------------------------------------------");

    if (userRole == UserRole.host) {
      final goLiveRes = await call.goLive();
      print("-----------------------------------------------------------");
      print("goLive result: ${goLiveRes.toString()}");
      print("-----------------------------------------------------------");

      // Notify server that the host is actually in the call and ready.
      // This triggers the room.status_changed broadcast to members.
      try {
        await _repo().hostReady(roomId);
      } catch (e) {
        print("hostReady call failed (non-fatal): $e");
      }
    }

    print("entercall: chk 6");

    ref.read(activeCallProvider.notifier).setCall(call);

    print("entercall: chk 7");

    _subscribeToCallState(call);
    _subscribeToCallEvents(call);
    _subscribeToWsEvents(_roomId!);

    print("entercall: chk 8");

    // Keep screen awake during the session.
    WakelockPlus.enable();

    state = AsyncData(
      (state.value ?? current).copyWith(
        getstreamCallId: getstreamCallId,
        isInCall: true,
      ),
    );

    print("entercall: chk 9 : end of function");

    // Watchdog: if no participants appear within 5s, the SFU connection
    // silently failed. Leave and rejoin once to recover.
    _scheduleParticipantCheck(call, connectOptions, userRole);
  }

  void _scheduleParticipantCheck(
    Call call,
    CallConnectOptions connectOptions,
    UserRole? userRole,
  ) {
    Future.delayed(const Duration(seconds: 5), () async {
      final participants = call.state.value.callParticipants;
      print("-----------------------------------------------------------");
      print("watchdog: participants after 5s: ${participants.length}");
      print("-----------------------------------------------------------");
      if (participants.isEmpty) {
        print("watchdog: 0 participants — forcing rejoin");
        try {
          await call.leave();
          await call.join(connectOptions: connectOptions);
          if (userRole == UserRole.host) {
            await call.goLive();
          }
          print("watchdog: rejoin completed");
          print(
            "watchdog: participants after rejoin: "
            "${call.state.value.callParticipants.length}",
          );
        } catch (e) {
          print("watchdog: rejoin failed: $e");
        }
      }
    });
  }

  void _subscribeToCallState(Call call) {
    _callStateSub?.cancel();
    _callStateSub = call.state.valueStream.listen((callState) {
      final current = state.value;
      if (current == null) return;

      // Host auto-grants send-audio permission to new participants
      if (current.isHost) {
        for (final p in callState.callParticipants) {
          if (!p.isLocal && !_grantedPermissionUsers.contains(p.userId)) {
            _grantedPermissionUsers.add(p.userId);
            call
                .grantPermissions(
                  userId: p.userId,
                  permissions: [CallPermission.sendAudio],
                )
                .catchError((_) {}); // fire-and-forget
          }
        }
      } else {
        // Non-host users should only hear the host, not other participants.
        // Disable audio tracks of non-host remote participants locally.
        for (final p in callState.callParticipants) {
          if (p.isLocal) continue;
          final track = call.getTrack(p.trackIdPrefix, SfuTrackType.audio);
          if (track == null) continue;
          if (p.roles.contains('host')) {
            track.enable();
          } else {
            track.disable();
          }
        }
      }

      final currentMuteState = {
        for (final m in current.members) m.userId: m.isMuted,
      };
      final updatedMembers = callState.callParticipants.map((p) {
        return RoomMemberModel(
          userId: p.userId,
          name: p.name.isNotEmpty ? p.name : p.userId,
          role: p.roles.contains('host') ? 'host' : 'user',
          isMuted: currentMuteState[p.userId] ?? !p.isAudioEnabled,
          joinedAt: DateTime.now(),
        );
      }).toList();

      state = AsyncData(current.copyWith(members: updatedMembers));
    });
  }

  /// Listens to GetStream SDK call events (e.g. call ended by host)
  /// and monitors the SFU connection for silent drops.
  void _subscribeToCallEvents(Call call) {
    _callEventsSub?.cancel();
    _callEventsSub = call.callEvents.listen((event) {
      if (event is StreamCallEndedEvent) {
        final current = state.value;
        if (current == null) return;

        // Another user (host) ended the call — clean up locally
        call.leave().catchError((_) {});
        ref.read(activeCallProvider.notifier).setCall(null);
        state = AsyncData(current.copyWith(isEnded: true, isInCall: false));
      }
    });

    // Monitor call connection status to detect silent SFU drops
    // (e.g. host sitting alone and the SFU times out).
    _callConnectionSub?.cancel();
    _callConnectionSub = call.state.valueStream
        .map((s) => s.status)
        .distinct()
        .listen((status) {
      print("-----------------------------------------------------------");
      print("call connection status changed: $status");
      print("-----------------------------------------------------------");
      if (status.isDisconnected || status.isIdle) {
        // Ignore disconnects triggered by our own leave/end actions.
        if (_isLeaving) return;

        final current = state.value;
        if (current == null || !current.isInCall) return;

        print("call connection lost unexpectedly — marking session ended");
        call.leave().catchError((_) {});
        ref.read(activeCallProvider.notifier).setCall(null);
        state = AsyncData(current.copyWith(isEnded: true, isInCall: false));
      }
    });
  }

  void _subscribeToWsEvents(String roomId) {
    _wsSub?.cancel();
    final wsService = ref.read(websocketServiceProvider);
    _wsSub = wsService.events.listen((event) async {
      final eventName = event['event'] as String;
      final payload = event['payload'] as Map<String, dynamic>? ?? {};

      if (payload['roomId'] != roomId) return;

      final current = state.value;
      if (current == null) return;

      switch (eventName) {
        case 'room.member_muted':
          final userId = payload['userId'] as String;
          final isMuted = payload['isMuted'] as bool;
          state = AsyncData(
            current.copyWith(
              members: current.members.map((m) {
                return m.userId == userId ? m.copyWith(isMuted: isMuted) : m;
              }).toList(),
            ),
          );

        case 'room.all_muted':
          state = AsyncData(
            current.copyWith(
              members: current.members
                  .map((m) => m.copyWith(isMuted: true))
                  .toList(),
            ),
          );

        case 'room.all_unmuted':
          state = AsyncData(
            current.copyWith(
              members: current.members
                  .map((m) => m.copyWith(isMuted: false))
                  .toList(),
            ),
          );

        case 'room.ended':
          {
            state = AsyncData(current.copyWith(isEnded: true));
            await leaveRoom();
          }

        case 'room.status_changed':
          final statusStr = payload['status'] as String?;
          if (statusStr != null) {
            final newStatus = RoomStatus.values.firstWhere(
              (s) => s.name == statusStr,
              orElse: () => current.status,
            );
            state = AsyncData(current.copyWith(status: newStatus));
          }

        case 'room.host_disconnected':
          final graceSeconds = payload['gracePeriodSeconds'] as num? ?? 30;
          state = AsyncData(
            current.copyWith(
              isHostDisconnected: true,
              hostGraceSeconds: graceSeconds.toInt(),
            ),
          );

        case 'room.host_reconnected':
          state = AsyncData(
            current.copyWith(isHostDisconnected: false, hostGraceSeconds: 0),
          );
      }
    });
  }

  Future<void> leaveRoom() async {
    _isLeaving = true;
    final call = ref.read(activeCallProvider);
    if (call != null) {
      // Disable mic before leaving to ensure audio track is properly released.
      await call.setMicrophoneEnabled(enabled: false).catchError((_) {});
      await call.leave();
      ref.read(activeCallProvider.notifier).setCall(null);
    }
    final roomId = _roomId;
    if (roomId != null) {
      try {
        await _repo().leaveRoom(roomId);
      } catch (_) {}
    }
    _cleanup();
  }

  Future<void> endRoom() async {
    _isLeaving = true;
    final call = ref.read(activeCallProvider);
    if (call != null) {
      await call.stopLive();
      await call.leave();
      ref.read(activeCallProvider.notifier).setCall(null);
    }
    final roomId = _roomId;
    if (roomId != null) {
      try {
        await _repo().endRoom(roomId);
      } on DioException catch (e) {
        // 409 means room is already not live — treat as successful end
        print("-----------------------------------------------------------");
        print("statusCode : ${e.response?.statusCode}");
        print("-----------------------------------------------------------");
        if (e.response?.statusCode == 409) {
          _cleanup();
        }
        ;
      }
    }
    _cleanup();
  }

  Future<void> muteMember(String userId, bool muted) async {
    final roomId = _roomId;
    if (roomId == null) return;
    await _repo().muteMember(roomId, userId, muted);
  }

  Future<void> muteAll() async {
    final roomId = _roomId;
    if (roomId == null) return;
    await _repo().muteAll(roomId);
  }

  Future<void> unmuteAll() async {
    final roomId = _roomId;
    if (roomId == null) return;
    await _repo().unmuteAll(roomId);
  }

  RoomRepositoryImpl _repo() =>
      RoomRepositoryImpl(RoomRemoteDatasource(ref.read(dioClientProvider)));

  void _cleanup() {
    _wsSub?.cancel();
    _callStateSub?.cancel();
    _callEventsSub?.cancel();
    _callConnectionSub?.cancel();
    _wsSub = null;
    _callStateSub = null;
    _callEventsSub = null;
    _callConnectionSub = null;
    _isLeaving = false;
    _grantedPermissionUsers.clear();
    // Allow screen to sleep again.
    WakelockPlus.disable();
  }
}

final roomSessionProvider =
    AsyncNotifierProvider<RoomSessionNotifier, RoomSession>(
      RoomSessionNotifier.new,
    );

//backup
  // Future<void> _enterCall({
  //   required String getstreamCallId,
  //   required String roomId,
  // }) async {
  //
  //   // final current = state.value;
  //   // print("-----------------------------------------------------------");
  //   // print("current : ${current.toString()}");
  //   // print("-----------------------------------------------------------");
  //
  //   // final current = state.value;
  //   // if (current == null) return;
  //
  //   if (useJoinApi) {
  //     final data = await _repo().joinRoom(_roomId!);
  //     callId = data['getstreamCallId'] as String? ?? getstreamCallId;
  //   }
  //   final authState = ref.read(authStateProvider);
  //   final userId = authState.whenOrNull(authenticated: (user) => user.userId);
  //   final userRole = authState.whenOrNull(authenticated: (user) => user.role);
  //   print("────────────────────────────────────────────────────────────────");
  //   print("userId : ${userId}, userRole: ${userRole.toString()}");
  //   print("────────────────────────────────────────────────────────────────");
  //
  //   // Request microphone permission before touching the audio stack.
  //   final micStatus = await Permission.microphone.request();
  //   if (!micStatus.isGranted) {
  //     throw Exception(
  //       'Microphone permission is required to join a room. Please grant it in Settings.',
  //     );
  //   }
  //
  //   if (userRole == UserRole.host) {
  //     // final token = await ref
  //     //     .read(secureStorageProvider)
  //     //     .read(StorageKeys.getstreamToken);
  //
  //     final call = StreamVideo.instance.makeCall(
  //       callType: StreamCallType.audioRoom(),
  //       id: getstreamCallId,
  //     );
  //
  //     await call.getOrCreate(
  //       audio: StreamAudioSettings(
  //         accessRequestEnabled: true,
  //         micDefaultOn: true,
  //       ),
  //     );
  //
  //     // final client = StreamVideo(
  //     //   AppConstants.getstreamApiKey,
  //     //   user: User.regular(
  //     //     userId: userId!,
  //     //     name: 'custom room test user 1',
  //     //     role: 'host',
  //     //   ),
  //     //   userToken: token,
  //     //   failIfSingletonExists: false,
  //     // );
  //
  //     // dart format off
  //       // print("──────────────────────────────────────────────────────────────────────────");
  //       // print("StreamVideo client initialized: ${client.currentUser.toJson()}");
  //       // print("──────────────────────────────────────────────────────────────────────────");
  //       // dart format on
  //
  //     // final result = await client.connect();
  //     // // if result wasn't successful, then result will return null
  //     // if (result.isSuccess) {
  //     //   print("────────────────────────────────────────────────────────────");
  //     //   print("StreamVideo client connected successfully");
  //     //   print("────────────────────────────────────────────────────────────");
  //     //
  //     //   final userToken = result.getDataOrNull();
  //     //   // userInfo.id will be slightly different from what you passed in. This is because the SDK will generate a unique ID for the user. Please use the generated ID across your app.
  //     //   final userInfo = client.currentUser;
  //     //   print("────────────────────────────────────────────────────────────");
  //     //   print("userInfo : ${userInfo.toJson()}");
  //     //   print("────────────────────────────────────────────────────────────");
  //     // } else {
  //     //   print("────────────────────────────────────────────────────────────");
  //     //   print("StreamVideo client failed to connect: ${result.toString()}");
  //     //   print("────────────────────────────────────────────────────────────");
  //     // }
  //
  //     // print("────────────────────────────────────────────────────────────");
  //     // print("Attempting to create/get call with ID: 'Your-call-ID'");
  //     // print("────────────────────────────────────────────────────────────");
  //     // final call = client.makeCall(
  //     //   callType: StreamCallType.audioRoom(),
  //     //   id: 'Your-call-ID-XYZ',
  //     // );
  //     // final newOrOldCall = await call.getOrCreate();
  //     // print("────────────────────────────────────────────────────────────");
  //     // print(
  //     //   "Call created or retrieved successfully: ${newOrOldCall.toString()}",
  //     // );
  //     // print("────────────────────────────────────────────────────────────");
  //
  //     await call.join();
  //     await call.goLive();
  //
  //     ref.read(activeCallProvider.notifier).setCall(call);
  //     // state = AsyncData(
  //     //   RoomSession(
  //     //     roomId: roomId,
  //     //     roomName: roomData.room.name,
  //     //     status: RoomStatus.live,
  //     //     members: [],
  //     //     getstreamCallId: roomData.room.getstreamCallId,
  //     //     isInCall: true,
  //     //     isHost: true,
  //     //   ),
  //     // );
  //
  //     // final hehe = call.callEvents.listen(
  //     //   (stev) => print("stream event: ${stev.toString()}"),
  //     // );
  //   } else {
  //     // final client = StreamVideo(
  //     //   AppConstants.getstreamApiKey,
  //     //   user: User.regular(userId: userId!, name: 'custom room test user 1'),
  //     //   userToken: roomData.getstreamToken,
  //     //   failIfSingletonExists: false,
  //     // );
  //     //
  //     // final result = await client.connect();
  //     // // if result wasn't successful, then result will return null
  //     // if (result.isSuccess) {
  //     //   print("────────────────────────────────────────────────────────────");
  //     //   print("guest StreamVideo client connected successfully");
  //     //   print("────────────────────────────────────────────────────────────");
  //     //
  //     //   final userToken = result.getDataOrNull();
  //     //   // userInfo.id will be slightly different from what you passed in. This is because the SDK will generate a unique ID for the user. Please use the generated ID across your app.
  //     //   final userInfo = client.currentUser;
  //     //   print("────────────────────────────────────────────────────────────");
  //     //   print("guest userInfo : ${userInfo.toJson()}");
  //     //   print("────────────────────────────────────────────────────────────");
  //     // } else {
  //     //   print("────────────────────────────────────────────────────────────");
  //     //   print(
  //     //     "guest StreamVideo client failed to connect: ${result.toString()}",
  //     //   );
  //     //   print("────────────────────────────────────────────────────────────");
  //     // }
  //     //
  //     // print("────────────────────────────────────────────────────────────");
  //     // print(
  //     //   "Guest user cannot create calls. Attempting to join call with ID: 'Your-call-ID'",
  //     // );
  //     // print("────────────────────────────────────────────────────────────");
  //     // final call = client.makeCall(
  //     //   callType: StreamCallType.audioRoom(),
  //     //   id: 'Your-call-ID-XYZ',
  //     // );
  //     // await call.addMembers([
  //     //   const UserInfo(id: 'charlie', role: 'call_member'),
  //     // ]);
  //
  //     final call = StreamVideo.instance.makeCall(
  //       callType: StreamCallType.audioRoom(),
  //       id: getstreamCallId,
  //     );
  //
  //     await call.getOrCreate(
  //       audio: StreamAudioSettings(
  //         accessRequestEnabled: true,
  //         micDefaultOn: true,
  //       ),
  //     );
  //
  //     // await call.grantPermissions(
  //     //   userId: userId,
  //     //   permissions: [CallPermission.sendAudio, CallPermission.joinCall],
  //     // );
  //     // await call.setMicrophoneEnabled(enabled: true);
  //     await call.join();
  //     ref.read(activeCallProvider.notifier).setCall(call);
  //     // state = AsyncData(
  //     //   RoomSession(
  //     //     roomId: roomId,
  //     //     roomName: roomData.room.name,
  //     //     members: [],
  //     //     status: RoomStatus.live,
  //     //     getstreamCallId: roomData.room.getstreamCallId,
  //     //     isInCall: true,
  //     //     isHost: false,
  //     //   ),
  //     // );
  //
  //     // final hehe = call.callEvents.listen(
  //     //   (stev) => print("stream event: ${stev.toString()}"),
  //     // );
  //   }
  //
  //   final call = StreamVideo.instance.makeCall(
  //     callType: StreamCallType.audioRoom(),
  //     id: callId,
  //   );
  //   await call.getOrCreate();
  //
  //   // Join with mic disabled — PTT controls it explicitly.
  //   final connectOptions = CallConnectOptions(
  //     microphone: TrackOption.disabled(),
  //   );
  //   await call.join(connectOptions: connectOptions);
  //   await call.setMicrophoneEnabled(enabled: false);
  //
  //   // Host must call goLive() to take the call out of backstage so
  //   // participants can join. This is required for the audio_room call type.
  //   if (current.isHost) {
  //     await call.goLive();
  //   }
  //
  //   ref.read(activeCallProvider.notifier).setCall(call);
  //
  //   _subscribeToCallState(call);
  //   _subscribeToWsEvents(_roomId!);
  //
  //   state = AsyncData(
  //     (state.value ?? current).copyWith(
  //       getstreamCallId: callId,
  //       isInCall: true,
  //     ),
  //   );
  // }
