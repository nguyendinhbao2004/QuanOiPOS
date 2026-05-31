import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/auth/domain/entities/current_user_profile.dart';
import 'package:quan_oi/features/auth/domain/entities/login_result.dart';
import 'package:quan_oi/features/auth/domain/repositories/auth_repository.dart';
import 'package:quan_oi/features/auth/domain/usecases/change_password_use_case.dart';
import 'package:quan_oi/features/auth/presentation/controllers/change_password_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';

void main() {
  test('change password success moves to success status', () async {
    final repository = _FakeChangePasswordRepository();
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(changePasswordNotifierProvider.notifier)
        .submit(
          currentPassword: 'OldP@ssw0rd123',
          newPassword: 'NewP@ssw0rd123',
        );

    final state = container.read(changePasswordNotifierProvider);
    expect(state.status, ChangePasswordStatus.success);
    expect(repository.currentPassword, 'OldP@ssw0rd123');
    expect(repository.newPassword, 'NewP@ssw0rd123');
  });

  test('change password failure keeps cleaned error message', () async {
    final repository = _FakeChangePasswordRepository(
      changePasswordError: Exception('Mật khẩu hiện tại không đúng'),
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(changePasswordNotifierProvider.notifier)
        .submit(currentPassword: 'wrong-pass', newPassword: 'NewP@ssw0rd123');

    final state = container.read(changePasswordNotifierProvider);
    expect(state.status, ChangePasswordStatus.failure);
    expect(state.errorMessage, 'Mật khẩu hiện tại không đúng');
  });
}

ProviderContainer _buildContainer(_FakeChangePasswordRepository repository) {
  return ProviderContainer(
    overrides: [
      changePasswordUseCaseProvider.overrideWithValue(
        ChangePasswordUseCase(repository),
      ),
    ],
  );
}

class _FakeChangePasswordRepository implements AuthRepository {
  final Object? changePasswordError;
  String? currentPassword;
  String? newPassword;

  _FakeChangePasswordRepository({this.changePasswordError});

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (changePasswordError != null) {
      throw changePasswordError!;
    }

    this.currentPassword = currentPassword;
    this.newPassword = newPassword;
  }

  @override
  Future<CurrentUserProfile> getCurrentUserProfile() {
    throw UnimplementedError();
  }

  @override
  Future<CurrentUserProfile> updateCurrentUserProfile({
    required String fullName,
    required String phone,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> confirmForgotPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> confirmRegistration({
    required String email,
    required String otpCode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> forgotPassword({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<LoginResult> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LoginResult?> restoreSession() {
    throw UnimplementedError();
  }
}
