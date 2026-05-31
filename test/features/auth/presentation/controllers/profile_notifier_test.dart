import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/domain/entities/current_user_profile.dart';
import 'package:quan_oi/features/auth/domain/entities/login_result.dart';
import 'package:quan_oi/features/auth/domain/repositories/auth_repository.dart';
import 'package:quan_oi/features/auth/domain/usecases/load_current_user_profile_use_case.dart';
import 'package:quan_oi/features/auth/domain/usecases/update_current_user_profile_use_case.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/controllers/profile_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';

void main() {
  test('load profile moves to ready status', () async {
    final repository = _FakeProfileRepository();
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container.read(profileNotifierProvider.notifier).load();

    final state = container.read(profileNotifierProvider);
    final authState = container.read(authNotifierProvider);
    expect(state.status, ProfileStatus.ready);
    expect(state.profile?.email, 'user@quanoi.test');
    expect(authState.fullName, 'Quan Oi User');
    expect(authState.phone, '0707834552');
  });

  test('update success submits fields and stores refreshed profile', () async {
    final repository = _FakeProfileRepository(
      profile: _profile(fullName: 'Updated User', phone: '0900000000'),
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(profileNotifierProvider.notifier)
        .submit(fullName: ' Updated User ', phone: ' 0900000000 ');

    final state = container.read(profileNotifierProvider);
    final authState = container.read(authNotifierProvider);
    expect(state.status, ProfileStatus.success);
    expect(state.profile?.fullName, 'Updated User');
    expect(repository.updatedFullName, 'Updated User');
    expect(repository.updatedPhone, '0900000000');
    expect(authState.fullName, 'Updated User');
    expect(authState.phone, '0900000000');
  });

  test('update failure keeps cleaned error message', () async {
    final repository = _FakeProfileRepository(
      updateError: Exception('Số điện thoại không hợp lệ'),
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(profileNotifierProvider.notifier)
        .submit(fullName: 'Quan Oi User', phone: 'bad-phone');

    final state = container.read(profileNotifierProvider);
    expect(state.status, ProfileStatus.failure);
    expect(state.errorMessage, 'Số điện thoại không hợp lệ');
  });
}

ProviderContainer _buildContainer(_FakeProfileRepository repository) {
  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(() => _FixedAuthNotifier()),
      loadCurrentUserProfileUseCaseProvider.overrideWithValue(
        LoadCurrentUserProfileUseCase(repository),
      ),
      updateCurrentUserProfileUseCaseProvider.overrideWithValue(
        UpdateCurrentUserProfileUseCase(repository),
      ),
    ],
  );
}

CurrentUserProfile _profile({
  String fullName = 'Quan Oi User',
  String phone = '0707834552',
}) {
  return CurrentUserProfile(
    accountId: 9,
    email: 'user@quanoi.test',
    fullName: fullName,
    phone: phone,
    accountType: AccountType.storeUser,
    status: 'Active',
    lastLogin: DateTime.utc(2026, 5, 31, 17, 22, 13),
  );
}

class _FixedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(
      status: AuthStatus.authenticated,
      accountType: AccountType.storeUser,
      fullName: 'Old User',
      email: 'user@quanoi.test',
      phone: '0100000000',
    );
  }
}

class _FakeProfileRepository implements AuthRepository {
  final CurrentUserProfile profile;
  final Object? updateError;
  String? updatedFullName;
  String? updatedPhone;

  _FakeProfileRepository({CurrentUserProfile? profile, this.updateError})
    : profile = profile ?? _profile();

  @override
  Future<CurrentUserProfile> getCurrentUserProfile() async {
    return profile;
  }

  @override
  Future<CurrentUserProfile> updateCurrentUserProfile({
    required String fullName,
    required String phone,
  }) async {
    if (updateError != null) {
      throw updateError!;
    }

    updatedFullName = fullName;
    updatedPhone = phone;
    return profile;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
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
