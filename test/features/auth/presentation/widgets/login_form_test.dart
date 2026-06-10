import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/auth/presentation/widgets/login_form.dart';

void main() {
  testWidgets('login form submits valid credentials', (tester) async {
    String? submittedEmail;
    String? submittedPassword;

    await tester.pumpWidget(
      _buildWidget(
        LoginForm(
          isLoading: false,
          errorMessage: null,
          onSubmit: (email, password) async {
            submittedEmail = email;
            submittedPassword = password;
          },
          onForgotPasswordPressed: () {},
          onRegisterPressed: () {},
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      '  user@quanoi.test  ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'ĐĂNG NHẬP NGAY'));
    await tester.pump();

    expect(submittedEmail, 'user@quanoi.test');
    expect(submittedPassword, 'password');
  });

  testWidgets('login form hides unfinished social login actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildWidget(
        LoginForm(
          isLoading: false,
          errorMessage: null,
          onSubmit: (_, _) async {},
          onForgotPasswordPressed: () {},
          onRegisterPressed: () {},
        ),
      ),
    );

    expect(find.text('Hoặc đăng nhập với'), findsNothing);
    expect(find.text('Google'), findsNothing);
    expect(find.text('Facebook'), findsNothing);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.text('Đăng ký ngay'), findsOneWidget);
  });
}

Widget _buildWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}
