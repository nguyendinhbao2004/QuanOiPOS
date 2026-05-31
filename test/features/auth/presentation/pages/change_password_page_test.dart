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
import 'package:quan_oi/features/auth/domain/usecases/change_password_use_case.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/pages/change_password_page.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  testWidgets('account hub opens change password route', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _FixedAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              accountType: AccountType.storeUser,
              fullName: 'Test User',
              email: 'user@quanoi.test',
            ),
          ),
        ),
        ..._lastActiveStoreOverrides(_FakeLastActiveStoreStorage()),
      ],
    );
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

    await tester.ensureVisible(find.text('Đổi mật khẩu'));
    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordPage), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  testWidgets('change password form validates required fields', (tester) async {
    await tester.pumpWidget(_buildPageWidget(_FakeChangePasswordRepository()));
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'HOÀN TẤT'));
    await tester.pump();

    expect(find.text('Vui lòng nhập mật khẩu'), findsNWidgets(3));
  });

  testWidgets('change password form validates length and confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(_buildPageWidget(_FakeChangePasswordRepository()));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), '123');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.enterText(find.byType(TextFormField).at(2), '654321');
    await tester.tap(find.widgetWithText(ElevatedButton, 'HOÀN TẤT'));
    await tester.pump();

    expect(find.text('Mật khẩu phải từ 6-32 ký tự'), findsOneWidget);
    expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
  });

  testWidgets('change password success submits and logs out locally', (
    tester,
  ) async {
    final repository = _FakeChangePasswordRepository();
    final authNotifier = _LogoutCountingAuthNotifier();
    await tester.pumpWidget(
      _buildPageWidget(repository, authNotifier: authNotifier),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'OldP@ssw0rd123');
    await tester.enterText(find.byType(TextFormField).at(1), 'NewP@ssw0rd123');
    await tester.enterText(find.byType(TextFormField).at(2), 'NewP@ssw0rd123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'HOÀN TẤT'));
    await tester.pumpAndSettle();

    expect(repository.currentPassword, 'OldP@ssw0rd123');
    expect(repository.newPassword, 'NewP@ssw0rd123');
    expect(authNotifier.logoutCount, 1);
    expect(
      find.text('Đổi mật khẩu thành công. Vui lòng đăng nhập lại.'),
      findsOneWidget,
    );
  });

  testWidgets('change password failure shows error and does not log out', (
    tester,
  ) async {
    final repository = _FakeChangePasswordRepository(
      changePasswordError: Exception('Mật khẩu hiện tại không đúng'),
    );
    final authNotifier = _LogoutCountingAuthNotifier();
    await tester.pumpWidget(
      _buildPageWidget(repository, authNotifier: authNotifier),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'OldP@ssw0rd123');
    await tester.enterText(find.byType(TextFormField).at(1), 'NewP@ssw0rd123');
    await tester.enterText(find.byType(TextFormField).at(2), 'NewP@ssw0rd123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'HOÀN TẤT'));
    await tester.pumpAndSettle();

    expect(repository.currentPassword, isNull);
    expect(repository.newPassword, isNull);
    expect(authNotifier.logoutCount, 0);
    expect(find.text('Mật khẩu hiện tại không đúng'), findsOneWidget);
    expect(
      find.text('Đổi mật khẩu thành công. Vui lòng đăng nhập lại.'),
      findsNothing,
    );
  });
}

Widget _buildPageWidget(
  _FakeChangePasswordRepository repository, {
  AuthNotifier? authNotifier,
}) {
  return ProviderScope(
    overrides: [
      changePasswordUseCaseProvider.overrideWithValue(
        ChangePasswordUseCase(repository),
      ),
      authNotifierProvider.overrideWith(
        () => authNotifier ?? _LogoutCountingAuthNotifier(),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const ChangePasswordPage()),
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

class _FixedAuthNotifier extends AuthNotifier {
  final AuthState fixedState;

  _FixedAuthNotifier(this.fixedState);

  @override
  AuthState build() {
    return fixedState;
  }
}

class _LogoutCountingAuthNotifier extends AuthNotifier {
  int logoutCount = 0;

  @override
  AuthState build() {
    return const AuthState(
      status: AuthStatus.authenticated,
      accountType: AccountType.storeUser,
      fullName: 'Test User',
      email: 'user@quanoi.test',
    );
  }

  @override
  Future<void> logout() async {
    logoutCount += 1;
    state = const AuthState.unauthenticated();
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
