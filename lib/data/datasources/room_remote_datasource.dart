import 'package:dio/dio.dart';

class RoomRemoteDatasource {
  final Dio _dio;

  RoomRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> getRooms() async {
    final response = await _dio.get('/rooms');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createRoom({
    required String name,
    String? description,
  }) async {
    final response = await _dio.post('/rooms', data: {
      'name': name,
      if (description != null) 'description': description,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRoom(String roomId) async {
    final response = await _dio.get('/rooms/$roomId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinRoom(String roomId) async {
    final response = await _dio.post('/rooms/$roomId/join');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startRoom(String roomId) async {
    final response = await _dio.post('/rooms/$roomId/start');
    return response.data as Map<String, dynamic>;
  }

  Future<void> hostReady(String roomId) async {
    await _dio.post('/rooms/$roomId/host-ready');
  }

  Future<void> leaveRoom(String roomId) async {
    await _dio.post('/rooms/$roomId/leave');
  }

  Future<void> deleteRoom(String roomId) async {
    await _dio.delete('/rooms/$roomId');
  }

  Future<Map<String, dynamic>> addMember(String roomId, String userId) async {
    final response = await _dio.post('/rooms/$roomId/members', data: {'userId': userId});
    return response.data as Map<String, dynamic>;
  }

  Future<void> removeMember(String roomId, String userId) async {
    await _dio.delete('/rooms/$roomId/members/$userId');
  }

  Future<Map<String, dynamic>> muteMember(String roomId, String userId, bool muted) async {
    final response = await _dio.patch('/rooms/$roomId/members/$userId/mute', data: {'muted': muted});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> muteAll(String roomId) async {
    final response = await _dio.post('/rooms/$roomId/mute-all');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unmuteAll(String roomId) async {
    final response = await _dio.post('/rooms/$roomId/unmute-all');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> kickAll(String roomId) async {
    final response = await _dio.post('/rooms/$roomId/kick-all');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> endRoom(String roomId) async {
    final response = await _dio.post('/rooms/$roomId/end');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMembers(String roomId) async {
    final response = await _dio.get('/rooms/$roomId/members');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSessionHistory(String roomId) async {
    final response = await _dio.get('/rooms/$roomId/sessions');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> activateRoom(String roomId) async {
    final response = await _dio.post('/admin/rooms/$roomId/activate');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deactivateRoom(String roomId) async {
    final response = await _dio.post('/admin/rooms/$roomId/deactivate');
    return response.data as Map<String, dynamic>;
  }
}
