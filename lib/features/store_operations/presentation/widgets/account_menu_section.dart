import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';

class AccountMenuSection extends StatelessWidget {
  final List<AccountMenuItemData> items;

  const AccountMenuSection({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            AccountMenuItem(
              title: items[i].title,
              leadingIcon: items[i].leadingIcon,
              trailingMeta: items[i].trailingMeta,
              onTap: items[i].onTap,
              enabled: items[i].enabled,
            ),
            if (i < items.length - 1)
              const Divider(height: 1, indent: AppConstants.spacingMd, endIndent: AppConstants.spacingMd),
          ],
        ],
      ),
    );
  }
}

class AccountMenuItemData {
  final String title;
  final IconData leadingIcon;
  final String? trailingMeta;
  final VoidCallback onTap;
  final bool enabled;

  const AccountMenuItemData({
    required this.title,
    required this.leadingIcon,
    required this.onTap,
    this.trailingMeta,
    this.enabled = true,
  });
}

class AccountMenuItem extends StatelessWidget {
  final String title;
  final IconData leadingIcon;
  final String? trailingMeta;
  final VoidCallback onTap;
  final bool enabled;

  const AccountMenuItem({
    super.key,
    required this.title,
    required this.leadingIcon,
    required this.onTap,
    this.trailingMeta,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingMd,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(leadingIcon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.labelSm.copyWith(
                  color: enabled ? AppColors.textPrimary : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailingMeta != null) ...[
              Text(
                trailingMeta!,
                style: AppTextStyles.bodyXs,
              ),
              const SizedBox(width: AppConstants.spacingSm),
            ],
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
