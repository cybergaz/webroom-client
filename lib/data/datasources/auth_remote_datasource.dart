import 'package:dio/dio.dart';

class AuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> signup({
    required String name,
    required String password,
    String? phone,
    String? email,
  }) async {
    final response = await _dio.post('/auth/signup', data: {
      'name': name,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkStatus(String requestId) async {
    final response = await _dio.get('/auth/status', queryParameters: {'requestId': requestId});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final response = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
  }

  Future<void> setPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    await _dio.post('/auth/set-password', data: {
      'phone': phone,
      'otp': otp,
      'newPassword': newPassword,
    });
  }
}
