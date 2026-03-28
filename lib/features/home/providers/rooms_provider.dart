import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/room_model.dart';
import '../../../data/repositories/room_repository_impl.dart';
import '../../../data/datasources/room_remote_datasource.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/websocket_service.dart';
import '../../../domain/enums/room_status.dart';
import '../../auth/providers/auth_provider.dart';

class RoomsNotifier extends AsyncNotifier<List<RoomModel>> {
  StreamSubscription? _wsSub;

  @override
  Future<List<RoomModel>> build() async {
    // Re-fetch rooms whenever auth state changes (login/logout).
    final auth = ref.watch(authStateProvider);
    if (auth is! AuthStateAuthenticated) {
      _wsSub?.cancel();
      return [];
    }

    _subscribeToWsEvents();

    ref.onDispose(() => _wsSub?.cancel());

    final repo = RoomRepositoryImpl(
      RoomRemoteDatasource(ref.read(dioClientProvider)),
    );
    return repo.getRooms();
  }

  void _subscribeToWsEvents() {
    _wsSub?.cancel();
    final wsService = ref.read(websocketServiceProvider);
    _wsSub = wsService.events.listen((event) {
      final eventName = event['event'] as String;

      switch (eventName) {
        case 'room.member_added':
        case 'room.member_removed':
          // Room assignment changed — refresh the full list
          refresh();
          break;

        case 'room.status_changed':
          // Update the room's status in-place without a full refetch
          final payload = event['payload'] as Map<String, dynamic>? ?? {};
          final roomId = payload['roomId'] as String?;
          final statusStr = payload['status'] as String?;
          if (roomId != null && statusStr != null) {
            _updateRoomStatus(roomId, statusStr);
          }
          break;
      }
    });
  }

  void _updateRoomStatus(String roomId, String statusStr) {
    final current = state.value;
    if (current == null) return;

    final status = RoomStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => RoomStatus.active,
    );

    state = AsyncData(
      current.map((room) {
        if (room.roomId == roomId) {
          return room.copyWith(status: status);
        }
        return room;
      }).toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = RoomRepositoryImpl(
        RoomRemoteDatasource(ref.read(dioClientProvider)),
      );
      return repo.getRooms();
    });
  }

  Future<RoomModel> createRoom({required String name, String? description}) async {
    final repo = RoomRepositoryImpl(
      RoomRemoteDatasource(ref.read(dioClientProvider)),
    );
    final room = await repo.createRoom(name: name, description: description);
    state = AsyncData([...?state.value, room]);
    return room;
  }
}

final roomsProvider = AsyncNotifierProvider<RoomsNotifier, List<RoomModel>>(RoomsNotifier.new);
