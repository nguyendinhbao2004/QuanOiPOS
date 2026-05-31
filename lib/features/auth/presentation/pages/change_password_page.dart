import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../controllers/change_password_state.dart';
import '../providers/auth_providers.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(changePasswordNotifierProvider.notifier).reset(),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await ref
        .read(changePasswordNotifierProvider.notifier)
        .submit(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

    if (!mounted) return;

    final state = ref.read(changePasswordNotifierProvider);
    if (state.status != ChangePasswordStatus.success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đổi mật khẩu thành công. Vui lòng đăng nhập lại.'),
      ),
    );
    await ref.read(authNotifierProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spacingMd,
            AppConstants.spacingMd,
            AppConstants.spacingMd,
            AppConstants.spacingXxl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Đổi mật khẩu',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingSm),
                Text(
                  'Sau khi hoàn tất, bạn cần đăng nhập lại để tiếp tục sử dụng ứng dụng.',
                  style: AppTextStyles.bodySm,
                ),
                const SizedBox(height: AppConstants.spacingXl),
                _PasswordField(
                  label: 'Mật khẩu hiện tại',
                  controller: _currentPasswordController,
                  enabled: !state.isSubmitting,
                  obscureText: _obscureCurrentPassword,
                  textInputAction: TextInputAction.next,
                  onVisibilityToggle: () {
                    setState(
                      () => _obscureCurrentPassword = !_obscureCurrentPassword,
                    );
                  },
                  validator: _validatePassword,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                _PasswordField(
                  label: 'Mật khẩu mới',
                  controller: _newPasswordController,
                  enabled: !state.isSubmitting,
                  obscureText: _obscureNewPassword,
                  textInputAction: TextInputAction.next,
                  onVisibilityToggle: () {
                    setState(() => _obscureNewPassword = !_obscureNewPassword);
                  },
                  validator: _validatePassword,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                _PasswordField(
                  label: 'Nhập lại mật khẩu',
                  controller: _confirmPasswordController,
                  enabled: !state.isSubmitting,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onVisibilityToggle: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                  onFieldSubmitted: (_) => _handleSubmit(),
                  validator: (value) {
                    final error = _validatePassword(value);
                    if (error != null) return error;
                    if (value != _newPasswordController.text) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    state.errorMessage!,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppConstants.spacingXl),
                ElevatedButton(
                  onPressed: state.isSubmitting ? null : _handleSubmit,
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('HOÀN TẤT'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (password.length < 6 || password.length > 32) {
      return 'Mật khẩu phải từ 6-32 ký tự';
    }
    return null;
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final bool obscureText;
  final TextInputAction textInputAction;
  final VoidCallback onVisibilityToggle;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String> validator;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.obscureText,
    required this.textInputAction,
    required this.onVisibilityToggle,
    required this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppTextStyles.labelSm,
            children: [
              TextSpan(
                text: ' *',
                style: AppTextStyles.labelSm.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          textInputAction: textInputAction,
          style: AppTextStyles.input,
          decoration: InputDecoration(
            hintText: 'Từ 6-32 ký tự',
            suffixIcon: IconButton(
              onPressed: enabled ? onVisibilityToggle : null,
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
        ),
      ],
    );
  }
}
