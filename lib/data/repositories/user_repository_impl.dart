import '../datasources/user_remote_datasource.dart';
import 'user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDatasource _datasource;

  UserRepositoryImpl(this._datasource);

  @override
  Future<void> forceLogout(String userId) async {
    await _datasource.forceLogout(userId);
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    final data = await _datasource.getPendingUsers();
    return (data['users'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> approveUser(String userId, {String? temporaryPassword}) async {
    await _datasource.approveUser(userId, temporaryPassword: temporaryPassword);
  }

  @override
  Future<void> rejectUser(String userId) async {
    await _datasource.rejectUser(userId);
  }

  @override
  Future<Map<String, dynamic>> getUsers({int page = 1, int limit = 50, String? search}) async {
    return _datasource.getUsers(page: page, limit: limit, search: search);
  }
}
