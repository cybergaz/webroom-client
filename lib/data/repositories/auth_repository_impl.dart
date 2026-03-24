import '../models/user_model.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/constants/storage_keys.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;
  final SecureStorageService _storage;

  AuthRepositoryImpl(this._datasource, this._storage);

  @override
  Future<String> signup({required String name, required String password, String? phone, String? email}) async {
    final data = await _datasource.signup(name: name, password: password, phone: phone, email: email);
    return data['requestId'] as String;
  }

  @override
  Future<String> checkStatus(String requestId) async {
    final data = await _datasource.checkStatus(requestId);
    return data['status'] as String;
  }

  @override
  Future<({UserModel user, String accessToken, String refreshToken, String getstreamToken})> login({
    required String phone,
    required String password,
  }) async {
    final data = await _datasource.login(phone: phone, password: password);
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    final getstreamToken = data['getstreamToken'] as String;

    await _storage.write(StorageKeys.accessToken, accessToken);
    await _storage.write(StorageKeys.refreshToken, refreshToken);
    await _storage.write(StorageKeys.getstreamToken, getstreamToken);
    await _storage.write(StorageKeys.userId, user.userId);
    await _storage.write(StorageKeys.userRole, user.role.name);
    await _storage.write(StorageKeys.userStatus, user.status);

    return (user: user, accessToken: accessToken, refreshToken: refreshToken, getstreamToken: getstreamToken);
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(StorageKeys.refreshToken);
      if (refreshToken != null) {
        await _datasource.logout(refreshToken);
      }
    } catch (_) {}
    await _storage.deleteAll();
  }
}
