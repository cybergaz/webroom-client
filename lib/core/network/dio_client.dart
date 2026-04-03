import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Cached app version, resolved once at startup.
String? _appVersion;

Future<void> initAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  _appVersion = info.version;
}

String _getDeviceName() {
  if (kIsWeb) return 'Web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'Android';
    case TargetPlatform.iOS:
      return 'iOS';
    case TargetPlatform.macOS:
      return 'Mac';
    case TargetPlatform.windows:
      return 'Windows';
    case TargetPlatform.linux:
      return 'Linux';
    default:
      return 'Unknown';
  }
}

final dioClientProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'X-Device-Name': _getDeviceName(),
        if (_appVersion != null) 'X-App-Version': _appVersion,
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(dio, storage, onForceLogout: () async {
      ref.read(authStateProvider.notifier).forceLogout();
    }),
    LogInterceptor(requestBody: true, responseBody: true),
  ]);

  return dio;
});
