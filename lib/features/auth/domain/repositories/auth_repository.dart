import '../entities/login_result.dart';

abstract class AuthRepository {
  Future<LoginResult> login({required String email, required String password});

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  });

  Future<void> confirmRegistration({
    required String email,
    required String otpCode,
  });

  Future<void> logout();

  Future<LoginResult?> restoreSession();
}
