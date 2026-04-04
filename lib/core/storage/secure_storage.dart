import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  /// Keys that survive a deleteAll() (e.g. device identity).
  static const _preservedKeys = {StorageKeys.deviceId};

  SecureStorageService() : _storage = const FlutterSecureStorage();

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    // Preserve persistent keys across logout
    final preserved = <String, String>{};
    for (final key in _preservedKeys) {
      final value = await _storage.read(key: key);
      if (value != null) preserved[key] = value;
    }
    await _storage.deleteAll();
    for (final entry in preserved.entries) {
      await _storage.write(key: entry.key, value: entry.value);
    }
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
