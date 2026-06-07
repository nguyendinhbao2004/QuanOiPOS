import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/domain/entities/store.dart';

class StoreWorkspaceHeader extends StatelessWidget {
  final VoidCallback onLogoTap;
  final VoidCallback onSearchTap;
  final VoidCallback onScanTap;
  final VoidCallback onNotificationTap;

  const StoreWorkspaceHeader({
    super.key,
    required this.onLogoTap,
    required this.onSearchTap,
    required this.onScanTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          key: const Key('store_workspace_header_logo_button'),
          onTap: onLogoTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingXs),
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: InkWell(
            key: const Key('store_workspace_header_search_pill'),
            onTap: onSearchTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
              ),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: Text(
                      'Tìm kiếm',
                      style: AppTextStyles.placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        _HeaderIconButton(
          tooltip: 'Quét mã',
          icon: Icons.qr_code_scanner_rounded,
          onPressed: onScanTap,
        ),
        const SizedBox(width: AppConstants.spacingXs),
        _HeaderIconButton(
          tooltip: 'Thông báo',
          icon: Icons.notifications_none_rounded,
          onPressed: onNotificationTap,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class StoreWorkspaceHeaderTitle extends StatelessWidget {
  final Store store;
  final String subtitle;

  const StoreWorkspaceHeaderTitle({
    super.key,
    required this.store,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.storeName.isEmpty ? 'Cửa hàng' : store.storeName,
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyXs.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
