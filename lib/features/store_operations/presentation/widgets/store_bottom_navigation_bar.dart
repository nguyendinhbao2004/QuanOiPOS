import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';

class StoreBottomNavigationBar extends StatelessWidget {
  final List<StoreBottomNavItemData> items;

  const StoreBottomNavigationBar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingSm),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: items
              .map(
                (item) => Expanded(
                  child: StoreBottomNavItem(
                    title: item.title,
                    icon: item.icon,
                    isActive: item.isActive,
                    isEnabled: item.isEnabled,
                    onTap: item.onTap,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class StoreBottomNavItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback? onTap;

  const StoreBottomNavItem({
    super.key,
    required this.title,
    required this.icon,
    this.isActive = false,
    this.isEnabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isActive
        ? AppColors.primary
        : isEnabled
        ? AppColors.textSecondary
        : AppColors.textMuted;

    return InkWell(
      onTap: isEnabled && !isActive ? onTap : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foregroundColor),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              title,
              style: AppTextStyles.bodyXs.copyWith(
                color: foregroundColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class StoreBottomNavItemData {
  final String title;
  final IconData icon;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback? onTap;

  const StoreBottomNavItemData({
    required this.title,
    required this.icon,
    this.isActive = false,
    this.isEnabled = false,
    this.onTap,
  });
}
