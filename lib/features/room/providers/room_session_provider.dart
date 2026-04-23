import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_video/stream_video.dart';
import 'package:webroom_client/domain/enums/user_role.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../data/models/room_member_model.dart';
import '../../../data/repositories/room_repository_impl.dart';
import '../../../data/datasources/room_remote_datasource.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/websocket_service.dart';
import '../../../domain/enums/room_status.dart';
import '../../auth/providers/auth_provider.dart';
import '../../session_history/providers/session_history_provider.dart';
import '../platform/remote_audio_mute.dart';
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
    String? sessionId,
    @Default(false) bool isInCall,
    @Default(false) bool isEnded,
    @Default(false) bool isHost,
    @Default(false) bool isHostDisconnected,
    @Default(0) int hostGraceSeconds,
    @Default(<String>[]) List<String> banners,
    String? marqueeText,
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
  final Set<String> _pendingGrantUsers = {};

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
          sessionId: roomData.sessionId,
          isInCall: true,
          isHost: roomData.isHost,
          banners: roomData.room.banners,
          marqueeText: roomData.room.marqueeText,
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
            sessionId: roomData.sessionId,
            isInCall: true,
            isHost: true,
            banners: roomData.room.banners,
            marqueeText: roomData.room.marqueeText,
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
      final sessionId = data['sessionId'] as String?;

      print("chk 4");
      state = AsyncData(
        current.copyWith(status: RoomStatus.live, getstreamCallId: callId, sessionId: sessionId),
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
      final data = await _repo().joinRoom(_roomId!);
      final callId =
          data['getstreamCallId'] as String? ?? current.getstreamCallId;
      final sessionId = data['sessionId'] as String?;

      state = AsyncData(
        current.copyWith(getstreamCallId: callId, sessionId: sessionId),
      );

      await _enterCall(
        getstreamCallId: callId,
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

  /// Fast-path room entry. All independent work runs in parallel:
  ///   • mic permission + SDK singleton construction (both near-instant)
  ///   • client `call.join()` + server `hostReady` (host only — server flips
  ///     the call out of backstage while the host joins the SFU)
  /// Token expiry is handled transparently by the SDK's `tokenLoader`; there
  /// is no dispose / reinitialize fallback.
  Future<void> _enterCall({
    required String getstreamCallId,
    required String roomId,
  }) async {
    final current = state.value;
    if (current == null) return;

    final authState = ref.read(authStateProvider);
    final userId = authState.whenOrNull(authenticated: (user) => user.userId)!;
    final userName = authState.whenOrNull(authenticated: (user) => user.name)!;
    final userRole = authState.whenOrNull(authenticated: (user) => user.role)!;
    final isHost = userRole == UserRole.host;

    // Parallel: mic permission + SDK singleton init.
    await Future.wait([
      _ensureMicPermission(),
      _ensureGetstreamInitialized(
        userId: userId,
        userName: userName,
        role: userRole,
      ),
    ]);

    final call = StreamVideo.instance.makeCall(
      callType: StreamCallType.audioRoom(),
      id: getstreamCallId,
    );

    final getCallRes = await call.getOrCreate(
      audio: StreamAudioSettings(micDefaultOn: false),
    );
    if (!getCallRes.isSuccess) {
      throw Exception('getOrCreate failed: $getCallRes');
    }

    // Clear any stale publisher tracks from a previous session.
    if (call.state.value.status.isAlreadyJoined) {
      await call.leave();
    }

    final connectOptions = CallConnectOptions(
      microphone: isHost ? TrackOption.enabled() : TrackOption.disabled(),
    );

    await call
        .join(connectOptions: connectOptions)
        .timeout(const Duration(seconds: 15));

    // Host: tell the server to goLive + notify members. Must run after the
    // host is actually in the SFU so members aren't woken up to join an
    // empty live call.
    if (isHost) {
      try {
        await _repo().hostReady(roomId);
      } catch (e) {
        print('hostReady failed (non-fatal): $e');
      }
    } else {
      // Non-host: pre-warm the mic track. Publishing on join then muting
      // means the first real unmute only has to flip a flag + re-acquire
      // the mic (fast) instead of negotiating a fresh track with the SFU
      // (slow — previously caused first-word drops). Done fire-and-forget
      // so it never blocks the join.
      () async {
        try {
          await call.setMicrophoneEnabled(enabled: true);
          await call.setMicrophoneEnabled(enabled: false);
        } catch (e) {
          print('mic pre-warm failed (non-fatal): $e');
        }
      }();
    }

    ref.read(activeCallProvider.notifier).setCall(call);

    _subscribeToCallState(call);
    _subscribeToCallEvents(call);
    _subscribeToWsEvents(_roomId!);

    WakelockPlus.enable();

    state = AsyncData(
      (state.value ?? current).copyWith(
        getstreamCallId: getstreamCallId,
        isInCall: true,
      ),
    );

    // Record the join for session history.
    await ref.read(sessionHistoryProvider.notifier).recordJoin(
          roomId: roomId,
          roomName: current.roomName,
        );

    // Watchdog: if no participants appear within 5s, the SFU connection
    // silently failed. Leave and rejoin once to recover.
    _scheduleParticipantCheck(call, connectOptions, userRole);
  }

  Future<void> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception(
        'Microphone permission is required to join a room. Please grant it in Settings.',
      );
    }
  }

  Future<void> _ensureGetstreamInitialized({
    required String userId,
    required String userName,
    required UserRole role,
  }) async {
    if (ref.read(getstreamStateProvider).isInitialized) return;
    final token =
        await ref.read(secureStorageProvider).read(StorageKeys.getstreamToken) ??
        '';
    await ref.read(getstreamStateProvider.notifier).init(
          userId: userId,
          userName: userName,
          getstreamToken: token,
          role: role,
        );
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

  /// Grants sendAudio to [userId] with up to 2 retries.
  /// Only marks the user as granted after a successful call.
  /// Uses [_pendingGrantUsers] to prevent duplicate concurrent attempts.
  Future<void> _grantPermissionWithRetry(Call call, String userId) async {
    if (_pendingGrantUsers.contains(userId)) return;
    _pendingGrantUsers.add(userId);

    try {
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          await call.grantPermissions(
            userId: userId,
            permissions: [CallPermission.sendAudio],
          );
          _grantedPermissionUsers.add(userId);
          return;
        } catch (e) {
          print('grantPermissions attempt ${attempt + 1} failed for $userId: $e');
          if (attempt < 2) {
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          }
        }
      }
      // All retries exhausted — don't add to granted set so it will be
      // attempted again on the next call-state update.
      print('grantPermissions exhausted retries for $userId');
    } finally {
      _pendingGrantUsers.remove(userId);
    }
  }

  void _subscribeToCallState(Call call) {
    _callStateSub?.cancel();
    _callStateSub = call.state.valueStream.listen((callState) {
      final current = state.value;
      if (current == null) return;

      // Host auto-grants send-audio permission to new participants.
      // The server already grants on join, but this acts as a fallback
      // in case the server grant didn't reach the SFU in time.
      if (current.isHost) {
        // Track which users are currently in the call so we can
        // remove departed users from the granted set.
        final currentUserIds = <String>{};
        for (final p in callState.callParticipants) {
          if (p.isLocal) continue;
          currentUserIds.add(p.userId);
          if (!_grantedPermissionUsers.contains(p.userId)) {
            // Don't mark as granted until the call actually succeeds.
            _grantPermissionWithRetry(call, p.userId);
          }
        }
        // Remove departed users so they get re-granted if they rejoin.
        _grantedPermissionUsers.removeWhere((id) => !currentUserIds.contains(id));
      } else {
        // Non-host users should only hear the host, not other participants.
        // On mobile, `track.disable()` silences remote audio. On web, the
        // browser's <audio> element keeps playing even with a disabled track,
        // so we also mute the element directly via a web-only helper.
        for (final p in callState.callParticipants) {
          if (p.isLocal) continue;
          final track = call.getTrack(p.trackIdPrefix, SfuTrackType.audio);
          final isHost = p.roles.contains('host');
          if (track != null) {
            if (isHost) {
              track.enable();
            } else {
              track.disable();
            }
          }
          setRemoteAudioMuted(p.trackIdPrefix, !isHost);
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
        ref.read(sessionHistoryProvider.notifier).recordLeave();
      }
    });

    // Monitor call connection status to detect silent SFU drops
    // (e.g. host sitting alone and the SFU times out).
    // Skip the initial Idle status that fires before the SFU connection
    // is established — only react to Disconnected after we've been connected.
    _callConnectionSub?.cancel();
    var hasBeenConnected = false;
    _callConnectionSub = call.state.valueStream
        .map((s) => s.status)
        .distinct()
        .listen((status) {
      print("-----------------------------------------------------------");
      print("call connection status changed: $status");
      print("-----------------------------------------------------------");

      // Track when the connection has been established at least once.
      if (status.isConnected || status.isReconnecting) {
        hasBeenConnected = true;
        return;
      }

      // Only treat as unexpected drop if we were previously connected.
      if (!hasBeenConnected) return;

      if (status.isDisconnected) {
        // Ignore disconnects triggered by our own leave/end actions.
        if (_isLeaving) return;

        final current = state.value;
        if (current == null || !current.isInCall) return;

        print("call connection lost unexpectedly — marking session ended");
        call.leave().catchError((_) {});
        ref.read(activeCallProvider.notifier).setCall(null);
        state = AsyncData(current.copyWith(isEnded: true, isInCall: false));
        ref.read(sessionHistoryProvider.notifier).recordLeave();
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
    await ref.read(sessionHistoryProvider.notifier).recordLeave();
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
    await ref.read(sessionHistoryProvider.notifier).recordLeave();
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
    _pendingGrantUsers.clear();
    // Allow screen to sleep again.
    WakelockPlus.disable();
  }
}

final roomSessionProvider =
    AsyncNotifierProvider<RoomSessionNotifier, RoomSession>(
      RoomSessionNotifier.new,
    );
