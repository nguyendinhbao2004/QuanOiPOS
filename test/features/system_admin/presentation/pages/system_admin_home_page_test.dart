import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/system_admin/presentation/pages/system_admin_home_page.dart';

void main() {
  testWidgets('system admin page renders desktop sidebar workspace', (
    tester,
  ) async {
    await _pumpSystemAdminPage(tester, const Size(1200, 800));

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Quản lý gói'), findsOneWidget);
    expect(find.text('Quản lý account'), findsOneWidget);
    expect(find.text('Doanh thu tháng'), findsOneWidget);
    expect(find.text('Cửa hàng hoạt động'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system admin page uses mobile drawer navigation', (
    tester,
  ) async {
    await _pumpSystemAdminPage(tester, const Size(390, 844));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Doanh thu tháng'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quản lý account'));
    await tester.pumpAndSettle();

    expect(find.text('Quản lý account'), findsOneWidget);
    expect(find.text('Tổng account'), findsOneWidget);
    expect(find.text('SystemAdmin'), findsOneWidget);
    expect(find.text('StoreUser'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSystemAdminPage(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authNotifierProvider.overrideWith(_TestAuthNotifier.new)],
      child: const MaterialApp(home: SystemAdminHomePage()),
    ),
  );
  await tester.pump();
}

class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(
      status: AuthStatus.authenticated,
      accountId: 1,
      accountType: AccountType.systemAdmin,
      fullName: 'Admin QuanOi',
      email: 'admin@quanoi.vn',
    );
  }

  @override
  Future<void> logout() async {
    state = const AuthState.unauthenticated();
  }
}
