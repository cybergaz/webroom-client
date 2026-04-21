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
  Future<AuthSession> signup({
    required String name,
    required String password,
    String? phone,
    String? email,
  }) async {
    final data = await _datasource.signup(name: name, password: password, phone: phone, email: email);
    return _persistSession(data);
  }

  @override
  Future<AuthSession> login({
    String? phone,
    String? email,
    required String password,
  }) async {
    final data = await _datasource.login(phone: phone, email: email, password: password);
    return _persistSession(data);
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

  Future<AuthSession> _persistSession(Map<String, dynamic> data) async {
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
    if (user.phone != null) await _storage.write(StorageKeys.userPhone, user.phone!);
    if (user.email != null) await _storage.write(StorageKeys.userEmail, user.email!);
    if (user.requestId != null) await _storage.write(StorageKeys.requestId, user.requestId!);

    return (user: user, accessToken: accessToken, refreshToken: refreshToken, getstreamToken: getstreamToken);
  }
}
