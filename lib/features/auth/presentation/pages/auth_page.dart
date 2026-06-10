import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../controllers/auth_state.dart';
import '../controllers/forgot_password_state.dart';
import '../controllers/register_state.dart';
import '../providers/auth_providers.dart';
import '../widgets/forgot_password_form.dart';
import '../widgets/login_form.dart';
import '../widgets/register_form.dart';

enum AuthFormMode { login, register, forgotPassword }

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  AuthFormMode _mode = AuthFormMode.login;

  @override
  Widget build(BuildContext context) {
    ref.listen<RegisterState>(registerNotifierProvider, (previous, next) {
      if (previous?.status == RegisterStatus.success ||
          next.status != RegisterStatus.success) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công. Vui lòng đăng nhập.'),
        ),
      );

      if (mounted) {
        setState(() => _mode = AuthFormMode.login);
      }

      ref.read(registerNotifierProvider.notifier).reset();
    });

    ref.listen<ForgotPasswordState>(forgotPasswordNotifierProvider, (
      previous,
      next,
    ) {
      if (previous?.status == ForgotPasswordStatus.success ||
          next.status != ForgotPasswordStatus.success) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lại mật khẩu thành công. Vui lòng đăng nhập.'),
        ),
      );

      if (mounted) {
        setState(() => _mode = AuthFormMode.login);
      }

      ref.read(forgotPasswordNotifierProvider.notifier).reset();
    });

    final authState = ref.watch(authNotifierProvider);
    final authForm = _buildAuthForm(authState);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final horizontalPadding = isDesktop
              ? AppConstants.spacingXxl
              : AppConstants.spacingMd;
          final verticalPadding = isDesktop
              ? AppConstants.spacingXl
              : AppConstants.spacingMd;
          final contentMinHeight =
              constraints.maxHeight -
              (verticalPadding * 2) -
              MediaQuery.paddingOf(context).vertical;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryLight,
                  AppColors.background,
                  AppColors.sidebar,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: contentMinHeight > 0 ? contentMinHeight : 0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _AuthFormCard(child: authForm),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthForm(AuthState authState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AuthHeader(),
        const SizedBox(height: AppConstants.spacingXl),
        if (_mode == AuthFormMode.login)
          LoginForm(
            isLoading: authState.isLoading,
            errorMessage: authState.status == AuthStatus.failure
                ? authState.errorMessage
                : null,
            onSubmit: (email, password) async {
              await ref
                  .read(authNotifierProvider.notifier)
                  .login(email: email, password: password);
            },
            onForgotPasswordPressed: () {
              ref.read(registerNotifierProvider.notifier).reset();
              ref.read(forgotPasswordNotifierProvider.notifier).reset();
              ref.read(authNotifierProvider.notifier).clearError();
              setState(() => _mode = AuthFormMode.forgotPassword);
            },
            onRegisterPressed: () {
              ref.read(registerNotifierProvider.notifier).reset();
              ref.read(forgotPasswordNotifierProvider.notifier).reset();
              setState(() => _mode = AuthFormMode.register);
              ref.read(authNotifierProvider.notifier).clearError();
            },
          )
        else if (_mode == AuthFormMode.register)
          RegisterForm(
            onBackToLoginPressed: () {
              setState(() => _mode = AuthFormMode.login);
              ref.read(forgotPasswordNotifierProvider.notifier).reset();
              ref.read(authNotifierProvider.notifier).clearError();
            },
          )
        else
          ForgotPasswordForm(
            onBackToLoginPressed: () {
              setState(() => _mode = AuthFormMode.login);
              ref.read(authNotifierProvider.notifier).clearError();
            },
          ),
      ],
    );
  }
}

class _AuthFormCard extends StatelessWidget {
  final Widget child;

  const _AuthFormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: child,
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppConstants.spacingSm),
          child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(height: AppConstants.spacingLg),
        Text(
          'QUÁN ƠI!',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          'Hệ thống quản lý nhà hàng thông minh',
          style: AppTextStyles.bodySm,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
