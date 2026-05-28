import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/domain/entities/store.dart';

class StoreWorkspaceHeader extends StatelessWidget {
  final Store store;
  final String subtitle;
  final VoidCallback onStoreTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback onNotificationTap;
  final bool canUpdateStore;

  const StoreWorkspaceHeader({
    super.key,
    required this.store,
    required this.subtitle,
    required this.onStoreTap,
    required this.onSettingsTap,
    required this.onNotificationTap,
    required this.canUpdateStore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            key: const Key('store_workspace_header_store_button'),
            onTap: onStoreTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spacingXs,
              ),
              child: Row(
                children: [
                  Container(
                    width: AppConstants.avatarSizeSm,
                    height: AppConstants.avatarSizeSm,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.storeName.isEmpty
                              ? 'Cửa hàng'
                              : store.storeName,
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
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
                  const SizedBox(width: AppConstants.spacingXs),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        IconButton(
          tooltip: canUpdateStore
              ? 'Cài đặt cửa hàng'
              : 'Bạn chưa có quyền cập nhật cửa hàng',
          onPressed: canUpdateStore ? onSettingsTap : null,
          icon: const Icon(Icons.settings_outlined),
        ),
        IconButton(
          tooltip: 'Thông báo',
          onPressed: onNotificationTap,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}
