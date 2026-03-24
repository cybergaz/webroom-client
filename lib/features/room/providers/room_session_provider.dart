import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_video/stream_video.dart';
import 'package:webroom_client/core/constants/app_constants.dart';
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
  String? _roomId;

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

      print("trying a dummy room");

      final authState = ref.read(authStateProvider);
      final userId = authState.whenOrNull(authenticated: (user) => user.userId);
      final userRole = authState.whenOrNull(authenticated: (user) => user.role);
      final token = await ref
          .read(secureStorageProvider)
          .read(StorageKeys.getstreamToken);
      print("────────────────────────────────────────────────────────────────");
      print("userId : ${userId}");
      print("────────────────────────────────────────────────────────────────");
      if (userRole == UserRole.host) {
        final client = StreamVideo(
          AppConstants.getstreamApiKey,
          user: User.regular(
            userId: userId!,
            name: 'custom room test user 1',
            role: 'host',
          ),
          userToken: token,
          failIfSingletonExists: false,
        );

        // dart format off
        print("──────────────────────────────────────────────────────────────────────────");
        print("StreamVideo client initialized: ${client.currentUser.toJson()}");
        print("──────────────────────────────────────────────────────────────────────────");
        // dart format on

        final result = await client.connect();
        // if result wasn't successful, then result will return null
        if (result.isSuccess) {
          print("────────────────────────────────────────────────────────────");
          print("StreamVideo client connected successfully");
          print("────────────────────────────────────────────────────────────");

          final userToken = result.getDataOrNull();
          // userInfo.id will be slightly different from what you passed in. This is because the SDK will generate a unique ID for the user. Please use the generated ID across your app.
          final userInfo = client.currentUser;
          print("────────────────────────────────────────────────────────────");
          print("userInfo : ${userInfo.toJson()}");
          print("────────────────────────────────────────────────────────────");
        } else {
          print("────────────────────────────────────────────────────────────");
          print("StreamVideo client failed to connect: ${result.toString()}");
          print("────────────────────────────────────────────────────────────");
        }

        print("────────────────────────────────────────────────────────────");
        print("Attempting to create/get call with ID: 'Your-call-ID'");
        print("────────────────────────────────────────────────────────────");
        final call = client.makeCall(
          callType: StreamCallType.development(),
          id: 'Your-call-ID-XYZ',
        );
        final newOrOldCall = await call.getOrCreate();
        print("────────────────────────────────────────────────────────────");
        print(
          "Call created or retrieved successfully: ${newOrOldCall.toString()}",
        );
        print("────────────────────────────────────────────────────────────");

        await call.goLive();
        await call.join();
        ref.read(activeCallProvider.notifier).setCall(call);
        state = AsyncData(
          const RoomSession(
            roomId: '',
            roomName: '',
            status: RoomStatus.live,
            members: [],
            getstreamCallId: 'Your-call-ID-XYZ',
            isInCall: true,
            isHost: true,
          ),
        );
      } else {
        final guest = User.guest(userId: userId!, name: "guest user 1");
        final client = StreamVideo(
          AppConstants.getstreamApiKey,
          user: guest,
          failIfSingletonExists: false,
        );

        final result = await client.connect();
        // if result wasn't successful, then result will return null
        if (result.isSuccess) {
          print("────────────────────────────────────────────────────────────");
          print("guest StreamVideo client connected successfully");
          print("────────────────────────────────────────────────────────────");

          final userToken = result.getDataOrNull();
          // userInfo.id will be slightly different from what you passed in. This is because the SDK will generate a unique ID for the user. Please use the generated ID across your app.
          final userInfo = client.currentUser;
          print("────────────────────────────────────────────────────────────");
          print("guest userInfo : ${userInfo.toJson()}");
          print("────────────────────────────────────────────────────────────");
        } else {
          print("────────────────────────────────────────────────────────────");
          print(
            "guest StreamVideo client failed to connect: ${result.toString()}",
          );
          print("────────────────────────────────────────────────────────────");
        }

        print("────────────────────────────────────────────────────────────");
        print(
          "Guest user cannot create calls. Attempting to join call with ID: 'Your-call-ID'",
        );
        print("────────────────────────────────────────────────────────────");
        final call = client.makeCall(
          callType: StreamCallType.development(),
          id: 'Your-call-ID-XYZ',
        );
        // await call.addMembers([
        //   const UserInfo(id: 'charlie', role: 'call_member'),
        // ]);
        await call.join();
        ref.read(activeCallProvider.notifier).setCall(call);
        state = AsyncData(
          const RoomSession(
            roomId: '',
            roomName: '',
            members: [],
            status: RoomStatus.live,
            getstreamCallId: 'Your-call-ID-XYZ',
            isInCall: true,
            isHost: false,
          ),
        );

        final hehe = call.callEvents;
      }

      final roomData = await _repo().getRoom(roomId);

      final session = RoomSession(
        roomId: roomId,
        roomName: roomData.room.name,
        status: roomData.room.status,
        isHost: roomData.isHost,
        members: [],
        getstreamCallId: roomData.room.getstreamCallId,
      );

      state = AsyncData(session);
      //
      // // Host navigating back to a room they already started — re-enter via getRoom credentials.
      // if (roomData.room.status == RoomStatus.live && roomData.isHost) {
      //   print("-----------------------------------------------------------");
      //   print('Auto-entering live room as host');
      //   print("-----------------------------------------------------------");
      //   await _enterCall(
      //     getstreamCallId: roomData.room.getstreamCallId,
      //     useJoinApi: false,
      //   );
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
    if (current == null || _roomId == null) return;

    try {
      final data = await _repo().startRoom(_roomId!);
      final callId =
          data['getstreamCallId'] as String? ?? current.getstreamCallId;

      state = AsyncData(
        current.copyWith(status: RoomStatus.live, getstreamCallId: callId),
      );

      await _enterCall(getstreamCallId: callId, useJoinApi: false);
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
        useJoinApi: true,
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
    required bool useJoinApi,
  }) async {
    final current = state.value;
    if (current == null) return;

    // Request microphone permission before touching the audio stack.
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception(
        'Microphone permission is required to join a room. Please grant it in Settings.',
      );
    }

    String callId = getstreamCallId;

    if (useJoinApi) {
      final data = await _repo().joinRoom(_roomId!);
      callId = data['getstreamCallId'] as String? ?? getstreamCallId;
    }

    final call = StreamVideo.instance.makeCall(
      callType: StreamCallType.audioRoom(),
      id: callId,
    );
    await call.getOrCreate();

    // Join with mic disabled — PTT controls it explicitly.
    final connectOptions = CallConnectOptions(
      microphone: TrackOption.disabled(),
    );
    await call.join(connectOptions: connectOptions);
    await call.setMicrophoneEnabled(enabled: false);

    // Host must call goLive() to take the call out of backstage so
    // participants can join. This is required for the audio_room call type.
    if (current.isHost) {
      await call.goLive();
    }

    ref.read(activeCallProvider.notifier).setCall(call);

    _subscribeToCallState(call);
    _subscribeToWsEvents(_roomId!);

    state = AsyncData(
      (state.value ?? current).copyWith(
        getstreamCallId: callId,
        isInCall: true,
      ),
    );
  }

  void _subscribeToCallState(Call call) {
    _callStateSub?.cancel();
    _callStateSub = call.state.valueStream.listen((callState) {
      final current = state.value;
      if (current == null) return;

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

  void _subscribeToWsEvents(String roomId) {
    _wsSub?.cancel();
    final wsService = ref.read(websocketServiceProvider);
    _wsSub = wsService.events.listen((event) {
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
    _wsSub = null;
    _callStateSub = null;
  }
}

final roomSessionProvider =
    AsyncNotifierProvider<RoomSessionNotifier, RoomSession>(
      RoomSessionNotifier.new,
    );
