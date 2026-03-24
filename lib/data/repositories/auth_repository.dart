import '../models/user_model.dart';

abstract class AuthRepository {
  Future<String> signup({required String name, required String password, String? phone, String? email});
  Future<String> checkStatus(String requestId);
  Future<({UserModel user, String accessToken, String refreshToken, String getstreamToken})> login({
    required String phone,
    required String password,
  });
  Future<void> logout();
}
