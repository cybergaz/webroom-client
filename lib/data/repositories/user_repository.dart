abstract class UserRepository {
  Future<void> forceLogout(String userId);
  Future<List<Map<String, dynamic>>> getPendingUsers();
  Future<void> approveUser(String userId, {String? temporaryPassword});
  Future<void> rejectUser(String userId);
  Future<Map<String, dynamic>> getUsers({int page = 1, int limit = 50, String? search});
}
