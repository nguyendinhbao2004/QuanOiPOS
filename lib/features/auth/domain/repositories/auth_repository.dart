import '../entities/login_result.dart';

abstract class AuthRepository {
  Future<LoginResult> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<LoginResult?> restoreSession();
}
