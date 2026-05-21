import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../controllers/register_state.dart';
import '../providers/auth_providers.dart';

class RegisterForm extends ConsumerStatefulWidget {
  final VoidCallback onBackToLoginPressed;

  const RegisterForm({super.key, required this.onBackToLoginPressed});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _detailsFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleDetailsSubmit() async {
    final isValid = _detailsFormKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await ref
        .read(registerNotifierProvider.notifier)
        .submitDetails(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
        );

    if (ref.read(registerNotifierProvider).step == RegisterStep.otp) {
      _passwordController.clear();
      _confirmPasswordController.clear();
    }
  }

  Future<void> _handleOtpSubmit() async {
    final isValid = _otpFormKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await ref
        .read(registerNotifierProvider.notifier)
        .confirmOtp(_otpController.text);
  }

  void _handleBackToLogin() {
    ref.read(registerNotifierProvider.notifier).reset();
    widget.onBackToLoginPressed();
  }

  void _handleBackToDetails() {
    ref.read(registerNotifierProvider.notifier).backToDetails();
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerNotifierProvider);

    if (registerState.step == RegisterStep.otp) {
      return _buildOtpStep(registerState);
    }

    return _buildDetailsStep(registerState);
  }

  Widget _buildDetailsStep(RegisterState registerState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Họ và tên', style: AppTextStyles.labelSm),
        const SizedBox(height: AppConstants.spacingSm),
        Form(
          key: _detailsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _fullNameController,
                enabled: !registerState.isLoading,
                textInputAction: TextInputAction.next,
                style: AppTextStyles.input,
                decoration: const InputDecoration(hintText: 'Nhập họ và tên'),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text('Email', style: AppTextStyles.labelSm),
              const SizedBox(height: AppConstants.spacingSm),
              TextFormField(
                controller: _emailController,
                enabled: !registerState.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: AppTextStyles.input,
                decoration: const InputDecoration(
                  hintText: 'Nhập email đăng ký',
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Vui lòng nhập email';
                  if (!email.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text('Mật khẩu', style: AppTextStyles.labelSm),
              const SizedBox(height: AppConstants.spacingSm),
              TextFormField(
                controller: _passwordController,
                enabled: !registerState.isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                style: AppTextStyles.input,
                decoration: InputDecoration(
                  hintText: 'Nhập mật khẩu',
                  suffixIcon: IconButton(
                    onPressed: registerState.isLoading
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').isEmpty) return 'Vui lòng nhập mật khẩu';
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text('Xác nhận mật khẩu', style: AppTextStyles.labelSm),
              const SizedBox(height: AppConstants.spacingSm),
              TextFormField(
                controller: _confirmPasswordController,
                enabled: !registerState.isLoading,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                style: AppTextStyles.input,
                decoration: InputDecoration(
                  hintText: 'Nhập lại mật khẩu',
                  suffixIcon: IconButton(
                    onPressed: registerState.isLoading
                        ? null
                        : () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                onFieldSubmitted: (_) => _handleDetailsSubmit(),
                validator: (value) {
                  if ((value ?? '').isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu';
                  }
                  if (value != _passwordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        if (registerState.errorMessage != null) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            registerState.errorMessage!,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppConstants.spacingLg),
        ElevatedButton(
          onPressed: registerState.isLoading ? null : _handleDetailsSubmit,
          child: registerState.status == RegisterStatus.submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('TẠO TÀI KHOẢN'),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: registerState.isLoading ? null : _handleBackToLogin,
            child: const Text('Quay lại đăng nhập'),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep(RegisterState registerState) {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mã OTP', style: AppTextStyles.labelSm),
          const SizedBox(height: AppConstants.spacingSm),
          TextFormField(
            controller: _otpController,
            enabled: !registerState.isLoading,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            style: AppTextStyles.input,
            decoration: const InputDecoration(hintText: 'Nhập mã OTP'),
            onFieldSubmitted: (_) => _handleOtpSubmit(),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) return 'Vui lòng nhập mã OTP';
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'Mã xác nhận đã được gửi đến ${registerState.email ?? 'email đăng ký'}.',
            style: AppTextStyles.bodyXs,
          ),
          if (registerState.errorMessage != null) ...[
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              registerState.errorMessage!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          ElevatedButton(
            onPressed: registerState.isLoading ? null : _handleOtpSubmit,
            child: registerState.status == RegisterStatus.confirming
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('XÁC NHẬN OTP'),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: registerState.isLoading
                      ? null
                      : _handleBackToDetails,
                  child: const Text('Sửa thông tin'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: TextButton(
                  onPressed: registerState.isLoading
                      ? null
                      : _handleBackToLogin,
                  child: const Text('Đăng nhập'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
