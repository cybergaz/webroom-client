import 'package:dio/dio.dart';

class UserRemoteDatasource {
  final Dio _dio;

  UserRemoteDatasource(this._dio);

  Future<void> forceLogout(String userId) async {
    await _dio.post('/users/$userId/force-logout');
  }

  Future<Map<String, dynamic>> getPendingUsers() async {
    final response = await _dio.get('/admin/users/pending');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> approveUser(String userId, {String? temporaryPassword}) async {
    final response = await _dio.post('/admin/users/$userId/approve', data: {
      if (temporaryPassword != null) 'temporaryPassword': temporaryPassword,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejectUser(String userId) async {
    final response = await _dio.post('/admin/users/$userId/reject');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUsers({int page = 1, int limit = 50, String? search}) async {
    final response = await _dio.get('/admin/users', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
    });
    return response.data as Map<String, dynamic>;
  }
}
