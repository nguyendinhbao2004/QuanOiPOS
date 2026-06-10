import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/config/router_config.dart';
import 'package:quan_oi/core/constants/app_constants.dart';
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
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  testWidgets('StoreUser opens app settings from account hub', (tester) async {
    final container = _buildContainer(AccountType.storeUser);
    addTearDown(container.dispose);

    await _pumpStoreHome(tester, container);

    expect(find.text('Cài đặt ứng dụng'), findsOneWidget);
    expect(find.text('Quy chế hoạt động'), findsNothing);
    expect(find.text('Chính sách bảo mật'), findsNothing);
    expect(find.text('Về ứng dụng'), findsNothing);
    expect(find.text('Đóng góp ý kiến'), findsNothing);

    await _tapAppSettings(tester);

    expect(find.text('Quy chế hoạt động'), findsOneWidget);
    expect(find.text('Chính sách bảo mật'), findsOneWidget);
    expect(find.text('Về ứng dụng'), findsOneWidget);
    expect(find.text('Đóng góp ý kiến'), findsOneWidget);
    expect(find.text('Giải quyết khiếu nại'), findsNothing);
    expect(find.byKey(const Key('app_settings_header')), findsOneWidget);
    expect(find.byKey(const Key('app_settings_profile_card')), findsOneWidget);
    expect(find.byKey(const Key('app_settings_promo_banner')), findsOneWidget);
    expect(find.byKey(const Key('app_settings_menu_section')), findsOneWidget);
    expect(find.byKey(const Key('app_settings_secure_footer')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('app_settings_profile_card'))).dy,
      lessThan(600),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('app_settings_promo_banner'))).dy,
      lessThan(600),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('app_settings_menu_section'))).dy,
      lessThan(600),
    );
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('0707967100'), findsOneWidget);
    expect(find.text('An toàn & bảo mật 100%'), findsOneWidget);
  });

  testWidgets(
    'StoreUser returns to account hub from app settings back button',
    (tester) async {
      final container = _buildContainer(AccountType.storeUser);
      addTearDown(container.dispose);

      await _pumpStoreHome(tester, container);
      await _tapAppSettings(tester);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('app_settings_header')), findsNothing);
      expect(find.text('Gói dịch vụ của tôi'), findsOneWidget);
      expect(find.text('Cài đặt ứng dụng'), findsOneWidget);
    },
  );

  testWidgets('StoreUser can slide promo banners in app settings', (
    tester,
  ) async {
    final container = _buildContainer(AccountType.storeUser);
    addTearDown(container.dispose);

    await _pumpStoreHome(tester, container);
    await _tapAppSettings(tester);
    await tester.ensureVisible(
      find.byKey(const Key('app_settings_promo_page_view')),
    );
    await tester.pumpAndSettle();

    final firstDot = tester.widget<Container>(
      find.byKey(const Key('app_settings_banner_dot_0')),
    );
    final firstDecoration = firstDot.decoration! as BoxDecoration;
    expect(firstDecoration.color, AppColors.primary);

    await tester.drag(
      find.byKey(const Key('app_settings_promo_page_view')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    final secondDot = tester.widget<Container>(
      find.byKey(const Key('app_settings_banner_dot_1')),
    );
    final secondDecoration = secondDot.decoration! as BoxDecoration;
    expect(secondDecoration.color, AppColors.primary);
  });

  testWidgets('StoreUser opens profile from app settings profile card', (
    tester,
  ) async {
    final container = _buildContainer(AccountType.storeUser);
    addTearDown(container.dispose);

    await _pumpStoreHome(tester, container);
    await _tapAppSettings(tester);
    await tester.tap(find.text('Chỉnh sửa thông tin'));
    await tester.pumpAndSettle();

    expect(find.text('Thông tin cá nhân'), findsOneWidget);
  });

  testWidgets('StoreUser opens operation regulations from app settings', (
    tester,
  ) async {
    final container = _buildContainer(AccountType.storeUser);
    addTearDown(container.dispose);

    await _pumpStoreHome(tester, container);
    await _tapAppSettings(tester);
    await _tapAppSettingsItem(tester, 'Quy chế hoạt động');

    expect(find.text('Quy chế hoạt động'), findsOneWidget);
    expect(
      find.byKey(const Key('operation_regulations_pdf_viewer')),
      findsOneWidget,
    );
  });

  testWidgets('StoreUser opens privacy policy from app settings', (
    tester,
  ) async {
    final container = _buildContainer(AccountType.storeUser);
    addTearDown(container.dispose);

    await _pumpStoreHome(tester, container);
    await _tapAppSettings(tester);
    await _tapAppSettingsItem(tester, 'Chính sách bảo mật');

    expect(find.text('Chính sách bảo mật'), findsOneWidget);
    expect(find.byKey(const Key('privacy_policy_pdf_viewer')), findsOneWidget);
  });

  testWidgets('StoreUser opens about app from app settings', (tester) async {
    final container = _buildContainer(AccountType.storeUser);
    addTearDown(container.dispose);

    await _pumpStoreHome(tester, container);
    await _tapAppSettings(tester);
    await _tapAppSettingsItem(tester, 'Về ứng dụng');

    expect(find.text('Về ứng dụng'), findsOneWidget);
    expect(find.byKey(const Key('about_app_header_card')), findsOneWidget);
    expect(find.byKey(const Key('about_app_logo')), findsOneWidget);
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(
      find.text('Phiên bản ứng dụng ${AppConstants.appVersion}'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('about_app_content_card')), findsOneWidget);
    expect(find.text('QUÁN ƠI'), findsOneWidget);
    expect(
      find.textContaining('QUẢN LÝ BÁN HÀNG CHỈ BẰNG MỘT CHIẾC ĐIỆN THOẠI'),
      findsWidgets,
    );
  });

  testWidgets('SystemAdmin is redirected away from app settings route', (
    tester,
  ) async {
    final container = _buildContainer(AccountType.systemAdmin);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/app-settings');
    await tester.pumpAndSettle();

    expect(find.text('Doanh thu tháng'), findsOneWidget);
    expect(find.byKey(const Key('app_settings_menu_section')), findsNothing);
  });

  testWidgets(
    'SystemAdmin is redirected away from operation regulations route',
    (tester) async {
      final container = _buildContainer(AccountType.systemAdmin);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      router.go('/operation-regulations');
      await tester.pumpAndSettle();

      expect(find.text('Doanh thu tháng'), findsOneWidget);
      expect(
        find.byKey(const Key('operation_regulations_pdf_viewer')),
        findsNothing,
      );
    },
  );

  testWidgets('SystemAdmin is redirected away from privacy policy route', (
    tester,
  ) async {
    final container = _buildContainer(AccountType.systemAdmin);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/privacy-policy');
    await tester.pumpAndSettle();

    expect(find.text('Doanh thu tháng'), findsOneWidget);
    expect(find.byKey(const Key('privacy_policy_pdf_viewer')), findsNothing);
  });

  testWidgets('SystemAdmin is redirected away from about app route', (
    tester,
  ) async {
    final container = _buildContainer(AccountType.systemAdmin);
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );

    router.go('/about-app');
    await tester.pumpAndSettle();

    expect(find.text('Doanh thu tháng'), findsOneWidget);
    expect(find.byKey(const Key('about_app_content_card')), findsNothing);
  });
}

Future<void> _pumpStoreHome(
  WidgetTester tester,
  ProviderContainer container,
) async {
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
}

Future<void> _tapAppSettings(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Cài đặt ứng dụng'));
  await tester.tap(find.text('Cài đặt ứng dụng'));
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _tapAppSettingsItem(WidgetTester tester, String title) async {
  await tester.ensureVisible(find.text(title));
  await tester.tap(find.text(title));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

ProviderContainer _buildContainer(AccountType accountType) {
  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(
          AuthState(
            status: AuthStatus.authenticated,
            accountType: accountType,
            fullName: 'Test User',
            email: 'user@quanoi.test',
            phone: '0707967100',
          ),
        ),
      ),
      ..._profileOverrides(_FakeProfileRepository()),
      ..._lastActiveStoreOverrides(_FakeLastActiveStoreStorage()),
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

class _FakeLastActiveStoreStorage implements LastActiveStoreStorage {
  int? lastStoreId;

  _FakeLastActiveStoreStorage({int? initialStoreId})
    : lastStoreId = initialStoreId;

  @override
  Future<int?> getLastActiveStoreId() async {
    return lastStoreId;
  }

  @override
  Future<void> saveLastActiveStoreId(int storeId) async {
    lastStoreId = storeId;
  }

  @override
  Future<void> clearLastActiveStoreId() async {
    lastStoreId = null;
  }
}

class _FakeProfileRepository implements AuthRepository {
  @override
  Future<CurrentUserProfile> getCurrentUserProfile() async {
    return CurrentUserProfile(
      accountId: 9,
      email: 'user@quanoi.test',
      fullName: 'Test User',
      phone: '0707967100',
      accountType: AccountType.storeUser,
      status: 'Active',
      lastLogin: DateTime.utc(2026, 5, 31, 17, 22, 13),
    );
  }

  @override
  Future<CurrentUserProfile> updateCurrentUserProfile({
    required String fullName,
    required String phone,
  }) async {
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
