import '../models/user_model.dart';

typedef AuthSession = ({UserModel user, String accessToken, String refreshToken, String getstreamToken});

abstract class AuthRepository {
  Future<AuthSession> signup({
    required String name,
    required String password,
    String? phone,
    String? email,
  });
  Future<AuthSession> login({
    String? phone,
    String? email,
    required String password,
  });
  Future<void> logout();
}
