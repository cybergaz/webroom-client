import '../models/room_model.dart';
import '../datasources/room_remote_datasource.dart';
import 'room_repository.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDatasource _datasource;

  RoomRepositoryImpl(this._datasource);

  @override
  Future<List<RoomModel>> getRooms() async {
    final data = await _datasource.getRooms();
    final rooms = data['rooms'] as List<dynamic>;
    return rooms
        .map((r) => RoomModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<RoomModel> createRoom({
    required String name,
    String? description,
  }) async {
    final data = await _datasource.createRoom(
      name: name,
      description: description,
    );
    return RoomModel.fromJson(data);
  }

  @override
  Future<
    ({
      RoomModel room,
      bool isHost,
      String getstreamToken,
      String getstreamCallType,
    })
  >
  getRoom(String roomId) async {
    final data = await _datasource.getRoom(roomId);
    // Detail endpoint uses 'roomId' key; RoomModel.fromJson expects 'id'
    final normalized = Map<String, dynamic>.from(data);
    normalized.putIfAbsent('id', () => normalized['roomId']);
    final room = RoomModel.fromJson(normalized);
    final isHost = data['isHost'] as bool? ?? false;
    final getstreamToken = data['getstreamToken'] as String? ?? '';
    final getstreamCallType =
        data['getstreamCallType'] as String? ?? 'audio_room';
    return (
      room: room,
      isHost: isHost,
      getstreamToken: getstreamToken,
      getstreamCallType: getstreamCallType,
    );
  }

  @override
  Future<Map<String, dynamic>> joinRoom(String roomId) async {
    return _datasource.joinRoom(roomId);
  }

  @override
  Future<Map<String, dynamic>> startRoom(String roomId) async {
    return _datasource.startRoom(roomId);
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    await _datasource.leaveRoom(roomId);
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await _datasource.deleteRoom(roomId);
  }

  @override
  Future<void> muteMember(String roomId, String userId, bool muted) async {
    await _datasource.muteMember(roomId, userId, muted);
  }

  @override
  Future<void> muteAll(String roomId) async {
    await _datasource.muteAll(roomId);
  }

  @override
  Future<void> unmuteAll(String roomId) async {
    await _datasource.unmuteAll(roomId);
  }

  @override
  Future<Map<String, dynamic>> endRoom(String roomId) async {
    return _datasource.endRoom(roomId);
  }

  @override
  Future<void> activateRoom(String roomId) async {
    await _datasource.activateRoom(roomId);
  }

  @override
  Future<void> deactivateRoom(String roomId) async {
    await _datasource.deactivateRoom(roomId);
  }
}
