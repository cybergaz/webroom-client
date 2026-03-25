import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  }) = _RoomSession;
}

class RoomSessionNotifier extends AsyncNotifier<RoomSession> {
  StreamSubscription? _wsSub;
  StreamSubscription? _callStateSub;
  StreamSubscription? _callEventsSub;
  String? _roomId;
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

  Future<void> _enterCall({
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

    final call_stat = await StreamVideo.instance.queryCalls(
      filterConditions: {'id': getstreamCallId},
    );

    print("-----------------------------------------------------------");
    print("if any old call stat : ${call_stat.toString()}");
    print("-----------------------------------------------------------");

    // final client = StreamVideo(
    //   AppConstants.getstreamApiKey,
    //   user: User.regular(
    //     userId: userId!,
    //     name: userName,
    //     role: userRole == UserRole.host ? 'host' : 'user',
    //   ),
    //   userToken: token!,
    //   failIfSingletonExists: false,
    // );

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
        micDefaultOn: true,
      ),
    );

    print("-----------------------------------------------------------");
    print("getCallRes isSuccess : ${getCallRes.isSuccess}");
    print("-----------------------------------------------------------");

    print("entercall: chk 4");

    if (userRole == UserRole.host) {
      await call.goLive();
    } else {}

    print("entercall: chk 5");

    final connectOptions = CallConnectOptions(
      microphone: TrackOption.enabled(),
    );
    await call.join(connectOptions: connectOptions);

    print("entercall: chk 6");

    ref.read(activeCallProvider.notifier).setCall(call);

    print("entercall: chk 7");

    _subscribeToCallState(call);
    _subscribeToCallEvents(call);
    _subscribeToWsEvents(_roomId!);

    print("entercall: chk 8");

    state = AsyncData(
      (state.value ?? current).copyWith(
        getstreamCallId: getstreamCallId,
        isInCall: true,
      ),
    );

    print("entercall: chk 9 : end of function");
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

  /// Listens to GetStream SDK call events (e.g. call ended by host).
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
  }

  void _subscribeToWsEvents(String roomId) {
    _wsSub?.cancel();
    final wsService = ref.read(websocketServiceProvider);
    _wsSub = wsService.events.listen((event) {
      print("-----------------------------------------------------------");
      print("event : ${event.toString()}");
      print("-----------------------------------------------------------");
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
          state = AsyncData(current.copyWith(isEnded: true));
      }
    });
  }

  Future<void> leaveRoom() async {
    final call = ref.read(activeCallProvider);
    if (call != null) {
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
    final call = ref.read(activeCallProvider);
    if (call != null) {
      await call.end();
      ref.read(activeCallProvider.notifier).setCall(null);
    }
    final roomId = _roomId;
    if (roomId != null) {
      await _repo().endRoom(roomId);
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
    _wsSub = null;
    _callStateSub = null;
    _callEventsSub = null;
    _grantedPermissionUsers.clear();
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
