import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/room_model.dart';
import '../../../data/repositories/room_repository_impl.dart';
import '../../../data/datasources/room_remote_datasource.dart';
import '../../../core/network/dio_client.dart';

class RoomsNotifier extends AsyncNotifier<List<RoomModel>> {
  @override
  Future<List<RoomModel>> build() async {
    final repo = RoomRepositoryImpl(
      RoomRemoteDatasource(ref.read(dioClientProvider)),
    );
    return repo.getRooms();
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
