import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/pages/auth_page.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';

void main() {
  testWidgets('auth page renders centered desktop login form', (tester) async {
    await _pumpAuthPage(tester, const Size(1200, 800));

    expect(
      find.text('Điều hành nhà hàng trên một màn hình rõ ràng.'),
      findsNothing,
    );
    expect(find.text('QUÁN ƠI!'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP NGAY'), findsOneWidget);
    expect(find.text('Google'), findsNothing);
    expect(find.text('Facebook'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auth page renders compact mobile login form', (tester) async {
    await _pumpAuthPage(tester, const Size(390, 844));

    expect(
      find.text('Điều hành nhà hàng trên một màn hình rõ ràng.'),
      findsNothing,
    );
    expect(find.text('QUÁN ƠI!'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP NGAY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpAuthPage(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authNotifierProvider.overrideWith(_TestAuthNotifier.new)],
      child: const MaterialApp(home: AuthPage()),
    ),
  );
  await tester.pump();
}

class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthState.unauthenticated();
  }

  @override
  Future<void> login({required String email, required String password}) async {}
}
