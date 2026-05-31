import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../domain/entities/current_user_profile.dart';
import '../controllers/profile_state.dart';
import '../providers/auth_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _boundProfileKey;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(profileNotifierProvider.notifier).reset();
      await ref.read(profileNotifierProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await ref
        .read(profileNotifierProvider.notifier)
        .submit(
          fullName: _fullNameController.text,
          phone: _phoneController.text,
        );
  }

  void _bindProfile(CurrentUserProfile profile) {
    final profileKey = [
      profile.accountId,
      profile.email,
      profile.fullName,
      profile.phone,
    ].join('|');

    if (_boundProfileKey == profileKey) {
      return;
    }

    _boundProfileKey = profileKey;
    _fullNameController.text = profile.fullName;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileNotifierProvider, (previous, next) {
      final profile = next.profile;
      if (profile != null) {
        _bindProfile(profile);
      }

      if (previous?.status != ProfileStatus.success &&
          next.status == ProfileStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
      }
    });

    final state = ref.watch(profileNotifierProvider);
    final profile = state.profile;
    if (profile != null) {
      _bindProfile(profile);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (state.isLoading && profile == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == ProfileStatus.failure && profile == null) {
              return _ProfileErrorView(
                message:
                    state.errorMessage ?? 'Không thể tải thông tin cá nhân',
                onRetry: () =>
                    ref.read(profileNotifierProvider.notifier).load(),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingMd,
                AppConstants.spacingLg,
                AppConstants.spacingMd,
                AppConstants.spacingXxl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ProfileAvatar(),
                    const SizedBox(height: AppConstants.spacingXl),
                    _ProfileTextField(
                      label: 'Họ và tên',
                      controller: _fullNameController,
                      enabled: !state.isSubmitting,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Vui lòng nhập họ và tên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    _ProfileTextField(
                      label: 'Email',
                      controller: _emailController,
                      enabled: false,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    _ProfileTextField(
                      label: 'Số điện thoại',
                      controller: _phoneController,
                      enabled: !state.isSubmitting,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSubmit(),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
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
                          : const Text('LƯU THAY ĐỔI'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 144,
        height: 144,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_outline_rounded,
          size: 72,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  const _ProfileTextField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.textInputAction,
    this.keyboardType,
    this.onFieldSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSm),
        const SizedBox(height: AppConstants.spacingSm),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: AppTextStyles.input,
          decoration: InputDecoration(hintText: label),
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
        ),
      ],
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(message, style: AppTextStyles.bodySm),
            const SizedBox(height: AppConstants.spacingMd),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
