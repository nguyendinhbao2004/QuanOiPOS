import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';

class AddTableTile extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback? onTap;

  const AddTableTile({super.key, required this.isEnabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isEnabled ? AppColors.primary : AppColors.textDisabled;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(
          color: isEnabled ? AppColors.primary : AppColors.border,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: SizedBox(
          height: 112,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isEnabled ? AppColors.primaryLight : AppColors.muted,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded, color: color, size: 26),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                isEnabled ? 'Thêm bàn mới' : 'Không có quyền thêm bàn',
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
