import '../models/room_model.dart';

abstract class RoomRepository {
  Future<List<RoomModel>> getRooms();
  Future<RoomModel> createRoom({required String name, String? description});
  Future<({RoomModel room, bool isHost, String getstreamToken, String getstreamCallType})> getRoom(String roomId);
  Future<Map<String, dynamic>> joinRoom(String roomId);
  Future<Map<String, dynamic>> startRoom(String roomId);
  Future<void> leaveRoom(String roomId);
  Future<void> deleteRoom(String roomId);
  Future<void> muteMember(String roomId, String userId, bool muted);
  Future<void> muteAll(String roomId);
  Future<void> unmuteAll(String roomId);
  Future<Map<String, dynamic>> endRoom(String roomId);
  Future<void> activateRoom(String roomId);
  Future<void> deactivateRoom(String roomId);
}
