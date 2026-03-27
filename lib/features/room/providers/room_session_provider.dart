import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Fetches room details only. Does NOT auto-start or auto-join.
  /// The UI decides what action to take based on the returned status.
  Future<void> loadRoom(String roomId) async {
    _roomId = roomId;
    state = const AsyncLoading();

    try {
      final authState = ref.read(authStateProvider);
      final userRole = authState.whenOrNull(authenticated: (user) => user.role);

      final roomData = await _repo().getRoom(roomId);
      final isHost = userRole == UserRole.host || roomData.isHost;

      // Set the actual status from the backend — don't hardcode anything.
      state = AsyncData(
        RoomSession(
          roomId: roomId,
          roomName: roomData.room.name,
          status: roomData.room.status,
          members: [],
          getstreamCallId: roomData.room.getstreamCallId,
          isInCall: false,
          isHost: isHost,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Host taps "Start Room" — calls backend start API, then enters GetStream call.
  /// Per GetStream docs: makeCall → getOrCreate → join → goLive (in that order).
  Future<void> startRoomAndEnter() async {
    final current = state.value;
    if (current == null || _roomId == null) return;

    try {
      // 1. Tell our backend to mark the room as live.
      final data = await _repo().startRoom(_roomId!);
      final callId =
          data['getstreamCallId'] as String? ?? current.getstreamCallId;

      state = AsyncData(
        current.copyWith(status: RoomStatus.live, getstreamCallId: callId),
      );

      // 2. Enter the GetStream call (host path).
      await _enterCall(getstreamCallId: callId, roomId: _roomId!);
    } catch (e) {
      // Revert to pre-call state so host can retry.
      state = AsyncData(current);
      rethrow;
    }
  }

  /// User taps "Join Room" (room must already be live).
  Future<void> joinRoomAndEnter() async {
    final current = state.value;
    if (current == null || _roomId == null) return;

    try {
      await _enterCall(
        getstreamCallId: current.getstreamCallId,
        roomId: _roomId!,
      );
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Re-fetches room state from backend (user polling while waiting for host).
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

  /// Core GetStream call entry — follows the documented flow:
  ///   makeCall → getOrCreate → join → goLive (host only, AFTER join)
  Future<void> _enterCall({
    required String getstreamCallId,
    required String roomId,
  }) async {
    final current = state.value;
    if (current == null) return;

    final authState = ref.read(authStateProvider);
    final userId = authState.whenOrNull(authenticated: (user) => user.userId);
    final userName = authState.whenOrNull(authenticated: (user) => user.name);
    final userRole = authState.whenOrNull(authenticated: (user) => user.role);
    final token = await ref
        .read(secureStorageProvider)
        .read(StorageKeys.getstreamToken);

    // Request microphone permission before touching the audio stack.
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception(
        'Microphone permission is required to join a room. Please grant it in Settings.',
      );
    }

    // Initialize GetStream SDK if not yet done.
    if (!ref.read(getstreamStateProvider).isInitialized) {
      await ref
          .read(getstreamStateProvider.notifier)
          .init(
            userId: userId!,
            userName: userName!,
            getstreamToken: token!,
            role: userRole!,
          );
    }

    final isHost = userRole == UserRole.host;
    var activeCallId = getstreamCallId;

    // Step 1+2: Find a usable (non-ended) call.
    // Old rooms may have permanently ended GetStream calls. Walk a suffix
    // chain (_r1, _r2, …) until we find one that is not ended, or create
    // a fresh one. Both host and user run the same deterministic logic so
    // they always converge on the same call ID.
    var call = await _findOrCreateUsableCall(
      baseId: getstreamCallId,
      isHost: isHost,
    );
    activeCallId = call.id;

    // Step 3: join — connects to the WebRTC session.
    // Host joins with mic enabled; listeners join with mic disabled (per docs).
    final connectOptions = CallConnectOptions(
      microphone: isHost ? TrackOption.enabled() : TrackOption.disabled(),
    );

    // For non-host: if the call is still in backstage the host hasn't gone
    // live yet, so we can't join. Throw a friendly error so the UI can retry.
    if (!isHost) {
      final backstage = call.state.value.isBackstage;
      if (backstage) {
        throw Exception(
          'The host has not started the session yet. Please try again in a moment.',
        );
      }
    }

    await call.join(connectOptions: connectOptions);

    // Step 4: goLive — host only, AFTER join.
    // Takes the call out of backstage so participants can join.
    if (isHost) {
      await call.goLive();
    }

    // Set the active call so the UI can react.
    ref.read(activeCallProvider.notifier).setCall(call);

    // Subscribe to state changes.
    _subscribeToCallState(call);
    _subscribeToCallEvents(call);
    _subscribeToWsEvents(_roomId!);

    state = AsyncData(
      (state.value ?? current).copyWith(
        getstreamCallId: activeCallId,
        isInCall: true,
        status: RoomStatus.live,
      ),
    );
  }

  void _subscribeToCallState(Call call) {
    _callStateSub?.cancel();
    _callStateSub = call.state.valueStream.listen((callState) {
      final current = state.value;
      if (current == null) return;

      // Host auto-grants send-audio permission to new participants.
      if (current.isHost) {
        for (final p in callState.callParticipants) {
          if (!p.isLocal && !_grantedPermissionUsers.contains(p.userId)) {
            _grantedPermissionUsers.add(p.userId);
            call
                .grantPermissions(
                  userId: p.userId,
                  permissions: [CallPermission.sendAudio],
                )
                .catchError((_) {});
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

  void _subscribeToCallEvents(Call call) {
    _callEventsSub?.cancel();
    _callEventsSub = call.callEvents.listen((event) {
      if (event is StreamCallEndedEvent) {
        final current = state.value;
        if (current == null) return;

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
      // Use stopLive + leave instead of call.end().
      // call.end() permanently terminates the GetStream call, making the
      // getstreamCallId unusable for future sessions of the same room.
      // stopLive returns to backstage; leave disconnects us from WebRTC.
      try {
        await call.stopLive();
      } catch (_) {}
      await call.leave();
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

  /// Walks a deterministic suffix chain to find a GetStream call that is not
  /// permanently ended. If the base call is ended, tries `{base}_r1`, `_r2`,
  /// etc. (up to 10 attempts). Both host and user run this same logic so
  /// they always land on the same call ID.
  Future<Call> _findOrCreateUsableCall({
    required String baseId,
    required bool isHost,
  }) async {
    var callId = baseId;

    for (var attempt = 0; attempt <= 10; attempt++) {
      final call = StreamVideo.instance.makeCall(
        callType: StreamCallType.audioRoom(),
        id: callId,
      );

      await call.getOrCreate(
        audio: StreamAudioSettings(
          micDefaultOn: isHost,
        ),
      );

      // If the call is not ended, it's usable.
      if (call.state.value.endedAt == null) {
        return call;
      }

      // This call was permanently ended — try the next suffix.
      callId = '${baseId}_r${attempt + 1}';
    }

    // All attempts exhausted — use the last one anyway (unlikely).
    final lastCall = StreamVideo.instance.makeCall(
      callType: StreamCallType.audioRoom(),
      id: callId,
    );
    await lastCall.getOrCreate(
      audio: StreamAudioSettings(micDefaultOn: isHost),
    );
    return lastCall;
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
