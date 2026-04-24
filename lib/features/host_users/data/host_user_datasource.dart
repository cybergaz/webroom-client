import 'package:dio/dio.dart';

import '../models/managed_user.dart';

class HostUserDatasource {
  final Dio _dio;

  HostUserDatasource(this._dio);

  Future<List<ManagedUser>> listUsers() async {
    final response = await _dio.get('/host/users');
    final data = response.data as Map<String, dynamic>;
    final users = (data['users'] as List<dynamic>).cast<Map<String, dynamic>>();
    return users.map(ManagedUser.fromJson).toList();
  }

  Future<void> updateUser(
    String userId, {
    String? name,
    String? password,
  }) async {
    await _dio.patch(
      '/host/users/$userId',
      data: {
        'name': ?name,
        'password': ?password,
      },
    );
  }

  Future<void> activateUser(String userId) async {
    await _dio.post('/host/users/$userId/activate');
  }

  Future<void> deactivateUser(String userId) async {
    await _dio.post('/host/users/$userId/deactivate');
  }

  Future<void> forceLogout(String userId) async {
    await _dio.post('/host/users/$userId/force-logout');
  }

  Future<void> allowDeviceChange(String userId) async {
    await _dio.post('/host/users/$userId/allow-device-change');
  }

  Future<void> resetDeviceLock(String userId) async {
    await _dio.post('/host/users/$userId/reset-device-lock');
  }

  Future<void> deleteUser(String userId) async {
    await _dio.delete('/host/users/$userId');
  }
}
