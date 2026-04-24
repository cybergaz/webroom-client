import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../constants/storage_keys.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Cached app version, resolved once at startup.
String? _appVersion;

/// Cached unique device ID, persisted across sessions.
String? _deviceId;

/// Cached detailed device name, e.g. "Android Samsung Galaxy S24:SM-S921B"
String _deviceName = 'Unknown';

Future<void> initAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  _appVersion = info.version;
}

/// Initialize (or retrieve) a persistent unique device ID.
Future<void> initDeviceId(SecureStorageService storage) async {
  _deviceId = await storage.read(StorageKeys.deviceId);
  if (_deviceId == null) {
    final deviceInfo = DeviceInfoPlugin();
    final info = await deviceInfo.deviceInfo;

    if (kIsWeb) {
      final web = await deviceInfo.webBrowserInfo;
      _deviceId = "${web.appCodeName}:${web.platform}";
      await storage.write(StorageKeys.deviceId, _deviceId!);
      return;
    }

    switch (info) {
      case AndroidDeviceInfo():
        _deviceId = "${info.model}:${info.id}";
      default:
        _deviceId = 'Unknown';
    }
    await storage.write(StorageKeys.deviceId, _deviceId!);
  }
}

/// Resolve a detailed device name using device_info_plus.
/// Call once at startup, after WidgetsFlutterBinding.ensureInitialized().
Future<void> initDeviceName() async {
  final deviceInfo = DeviceInfoPlugin();

  if (kIsWeb) {
    final web = await deviceInfo.webBrowserInfo;
    _deviceName = 'Web ${web.browserName.name}';
    return;
  }

  try {
    final info = await deviceInfo.deviceInfo;
    switch (info) {
      case AndroidDeviceInfo():
        // e.g. "Android Samsung Galaxy S24:SM-S921B"
        final brand = _capitalize(info.brand);
        final model = info.model;
        // final product = info.product;
        // model and product are sometimes the same; prefer model
        _deviceName = 'Android $brand $model';
      case IosDeviceInfo():
        // e.g. "iOS iPhone 15 Pro:iPhone16,1"
        final modelName = info.modelName; // e.g. "iPhone 15 Pro"
        final machine = info.utsname.machine; // e.g. "iPhone16,1"
        _deviceName = 'iOS $modelName:$machine';
      case MacOsDeviceInfo():
        _deviceName = 'Mac ${info.model}';
      case WindowsDeviceInfo():
        _deviceName = 'Windows ${info.computerName}';
      case LinuxDeviceInfo():
        _deviceName = 'Linux ${info.prettyName}';
      default:
        _deviceName = 'Unknown';
    }
  } catch (_) {
    _deviceName = 'Unknown';
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

final dioClientProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'X-Device-Name': _deviceName,
        if (_appVersion != null) 'X-App-Version': _appVersion,
        if (_deviceId != null) 'X-Device-Id': _deviceId,
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(
      dio,
      storage,
      onForceLogout: () async {
        ref.read(authStateProvider.notifier).forceLogout();
      },
    ),
    LogInterceptor(requestBody: true, responseBody: true),
  ]);

  return dio;
});
