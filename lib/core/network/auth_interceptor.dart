import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../constants/storage_keys.dart';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthInterceptor(this._dio, this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var token = await _storage.read(StorageKeys.accessToken);

    // Access token missing — try refreshing proactively before sending
    if (token == null) {
      token = await _tryRefresh();
    }

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// Attempts a token refresh. Returns the new access token, or null on failure.
  Future<String?> _tryRefresh() async {
    try {
      final refreshToken = await _storage.read(StorageKeys.refreshToken);
      if (refreshToken == null) return null;

      final refreshDio = Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ));
      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data['accessToken'] as String;
      final newRefreshToken = response.data['refreshToken'] as String;
      await _storage.write(StorageKeys.accessToken, newAccessToken);
      await _storage.write(StorageKeys.refreshToken, newRefreshToken);
      return newAccessToken;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final newToken = await _tryRefresh();
      if (newToken != null) {
        // Retry the original request with the fresh token
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        try {
          final retryResponse = await _dio.fetch(opts);
          handler.resolve(retryResponse);
          return;
        } catch (_) {}
      }
      // Refresh failed — clear storage so the app redirects to login
      await _storage.deleteAll();
      handler.next(err);
    } else {
      handler.next(err);
    }
  }
}
