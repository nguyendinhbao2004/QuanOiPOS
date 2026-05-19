import 'package:flutter/material.dart';

import '../../../../core/theme/index.dart';

class LogoutActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LogoutActionButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: Text(
          'Đăng xuất',
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
