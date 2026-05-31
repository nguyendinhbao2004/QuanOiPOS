import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/config/router_config.dart';
import 'package:quan_oi/core/storage/last_active_store_storage.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/domain/entities/current_user_profile.dart';
import 'package:quan_oi/features/auth/domain/entities/login_result.dart';
import 'package:quan_oi/features/auth/domain/repositories/auth_repository.dart';
import 'package:quan_oi/features/auth/domain/usecases/load_current_user_profile_use_case.dart';
import 'package:quan_oi/features/auth/domain/usecases/update_current_user_profile_use_case.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/pages/profile_page.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/store_operations/presentation/widgets/user_profile_card.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  testWidgets('account hub opens profile route from profile card', (
    tester,
  ) async {
    final repository = _FakeProfileRepository();
    final container = _buildRouterContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/store-home');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(UserProfileCard));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Thông tin cá nhân'), findsOneWidget);
  });

  testWidgets('profile page preloads profile and keeps email disabled', (
    tester,
  ) async {
    final repository = _FakeProfileRepository();
    final container = _buildPageContainer(repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildPageWidget(container));
    await tester.pumpAndSettle();

    expect(find.text('Quan Oi User'), findsOneWidget);
    expect(find.text('user@quanoi.test'), findsOneWidget);
    expect(find.text('0707834552'), findsOneWidget);

    final emailField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(1),
    );
    expect(emailField.enabled, isFalse);
  });

  testWidgets('profile page validates required editable fields', (
    tester,
  ) async {
    final repository = _FakeProfileRepository();
    final container = _buildPageContainer(repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildPageWidget(container));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(2), '');
    await tester.tap(find.widgetWithText(ElevatedButton, 'LƯU THAY ĐỔI'));
    await tester.pump();

    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
    expect(find.text('Vui lòng nhập số điện thoại'), findsOneWidget);
  });

  testWidgets('profile page submits update and syncs auth state', (
    tester,
  ) async {
    final repository = _FakeProfileRepository();
    final container = _buildPageContainer(repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildPageWidget(container));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Updated User');
    await tester.enterText(find.byType(TextFormField).at(2), '0900000000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'LƯU THAY ĐỔI'));
    await tester.pumpAndSettle();

    final authState = container.read(authNotifierProvider);
    expect(repository.updatedFullName, 'Updated User');
    expect(repository.updatedPhone, '0900000000');
    expect(authState.fullName, 'Updated User');
    expect(authState.phone, '0900000000');
    expect(find.text('Cập nhật thông tin thành công'), findsOneWidget);
  });
}

ProviderContainer _buildRouterContainer(_FakeProfileRepository repository) {
  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(() => _FixedAuthNotifier()),
      ..._profileOverrides(repository),
      ..._lastActiveStoreOverrides(_FakeLastActiveStoreStorage()),
    ],
  );
}

ProviderContainer _buildPageContainer(_FakeProfileRepository repository) {
  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(() => _FixedAuthNotifier()),
      ..._profileOverrides(repository),
    ],
  );
}

List<Override> _profileOverrides(_FakeProfileRepository repository) {
  return [
    loadCurrentUserProfileUseCaseProvider.overrideWithValue(
      LoadCurrentUserProfileUseCase(repository),
    ),
    updateCurrentUserProfileUseCaseProvider.overrideWithValue(
      UpdateCurrentUserProfileUseCase(repository),
    ),
  ];
}

Widget _buildPageWidget(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: AppTheme.light, home: const ProfilePage()),
  );
}

List<Override> _lastActiveStoreOverrides(_FakeLastActiveStoreStorage storage) {
  return [
    loadLastActiveStoreUseCaseProvider.overrideWithValue(
      LoadLastActiveStoreUseCase(storage),
    ),
    saveLastActiveStoreUseCaseProvider.overrideWithValue(
      SaveLastActiveStoreUseCase(storage),
    ),
    clearLastActiveStoreUseCaseProvider.overrideWithValue(
      ClearLastActiveStoreUseCase(storage),
    ),
  ];
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
      fullName: 'Quan Oi User',
      email: 'user@quanoi.test',
      phone: '0707834552',
    );
  }
}

class _FakeLastActiveStoreStorage implements LastActiveStoreStorage {
  int? lastStoreId;

  @override
  Future<void> clearLastActiveStoreId() async {
    lastStoreId = null;
  }

  @override
  Future<int?> getLastActiveStoreId() async {
    return lastStoreId;
  }

  @override
  Future<void> saveLastActiveStoreId(int storeId) async {
    lastStoreId = storeId;
  }
}

class _FakeProfileRepository implements AuthRepository {
  Object? updateError;
  String? updatedFullName;
  String? updatedPhone;

  @override
  Future<CurrentUserProfile> getCurrentUserProfile() async {
    return _profile(
      fullName: updatedFullName ?? 'Quan Oi User',
      phone: updatedPhone ?? '0707834552',
    );
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
    return getCurrentUserProfile();
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
