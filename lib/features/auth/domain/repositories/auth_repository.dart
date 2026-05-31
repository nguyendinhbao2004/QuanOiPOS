import '../entities/login_result.dart';
import '../entities/current_user_profile.dart';

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

  Future<void> forgotPassword({required String email});

  Future<void> confirmForgotPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<CurrentUserProfile> getCurrentUserProfile();

  Future<CurrentUserProfile> updateCurrentUserProfile({
    required String fullName,
    required String phone,
  });

  Future<void> logout();

  Future<LoginResult?> restoreSession();
}
