import 'package:dio/dio.dart';
import 'package:webroom_client/features/auth/providers/auth_provider.dart';
import '../storage/secure_storage.dart';
import '../constants/storage_keys.dart';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  final Dio _dio;
  final SecureStorageService _storage;
  final Future<void> Function() _onForceLogout;

  /// When true, the refresh token is dead and the user must re-login.
  bool _refreshTokenDead = false;
  bool get isRefreshTokenDead => _refreshTokenDead;

  AuthInterceptor(this._dio, this._storage, {required Future<void> Function() onForceLogout})
      : _onForceLogout = onForceLogout;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var token = await _storage.read(StorageKeys.accessToken);

    // Access token missing — try refreshing proactively before sending
    if (token == null && !_refreshTokenDead) {
      token = await _tryRefresh();
    }

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// Attempts a token refresh. Returns the new access token, or null on failure.
  Future<String?> _tryRefresh() async {
    if (_refreshTokenDead) return null;

    final refreshToken = await _storage.read(StorageKeys.refreshToken);
    if (refreshToken == null) {
      print('Token refresh skipped: no refresh token in storage');
      // Don't set _refreshTokenDead here — a fresh login will provide new tokens.
      // Only mark dead on explicit 403 rejection from the refresh endpoint.
      return null;
    }

    print('Attempting token refresh...');
    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: _dio.options.connectTimeout,
          receiveTimeout: _dio.options.receiveTimeout,
          headers: {'Content-Type': 'application/json'},
        ),
      );
      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data['accessToken'] as String;
      final newRefreshToken = response.data['refreshToken'] as String;
      final newGetstreamToken = response.data['getstreamToken'] as String?;
      await _storage.write(StorageKeys.accessToken, newAccessToken);
      await _storage.write(StorageKeys.refreshToken, newRefreshToken);
      if (newGetstreamToken != null) {
        await _storage.write(StorageKeys.getstreamToken, newGetstreamToken);
      }
      print('Token refresh succeeded');
      return newAccessToken;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        // Refresh token is permanently invalid — force logout.
        print('Refresh token rejected (403) — clearing storage for re-login');
        _refreshTokenDead = true;
        await _storage.deleteAll();
        await _onForceLogout();
      } else {
        print('Token refresh failed: ${e.response?.statusCode} ${e.message}');
      }
      return null;
    } catch (e) {
      print('Token refresh failed: $e');
      return null;
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    print("-----------------------------------------------------------");
    print("err : ${err.toString()}");
    print("-----------------------------------------------------------");

    print("-----------------------------------------------------------");
    print("statusCode : ${err.response?.statusCode}");
    print("-----------------------------------------------------------");

    print("-----------------------------------------------------------");
    print("_refreshTokenDead : ${_refreshTokenDead}");
    print("-----------------------------------------------------------");
    if (err.response?.statusCode == 401 && !_refreshTokenDead) {
      print('we are going to refresh');
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
    }
    handler.next(err);
  }
}
