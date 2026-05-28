import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/domain/entities/store.dart';

class StoreSwitchListTile extends StatelessWidget {
  final Store store;
  final bool isActiveStore;
  final VoidCallback? onTap;

  const StoreSwitchListTile({
    super.key,
    required this.store,
    required this.isActiveStore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final borderColor = isActiveStore ? AppColors.primary : AppColors.border;
    final backgroundColor = isActiveStore
        ? AppColors.primaryLight
        : AppColors.surface;
    final iconBackgroundColor = isActiveStore
        ? AppColors.primary
        : AppColors.muted;
    final iconColor = isActiveStore ? AppColors.surface : AppColors.textMuted;

    return Opacity(
      opacity: isEnabled ? 1 : 0.62,
      child: Card(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          side: BorderSide(color: borderColor, width: isActiveStore ? 1.5 : 1),
        ),
        child: InkWell(
          key: Key('switch_store_${store.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: Icon(Icons.storefront_rounded, color: iconColor),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              store.storeName.isEmpty
                                  ? 'Cửa hàng chưa đặt tên'
                                  : store.storeName,
                              style: AppTextStyles.labelSm.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingXs),
                          _StoreStatusPill(status: store.status),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        store.address.isEmpty
                            ? 'Chưa có địa chỉ'
                            : store.address,
                        style: AppTextStyles.bodyXs.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isActiveStore) ...[
                  const SizedBox(width: AppConstants.spacingSm),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreStatusPill extends StatelessWidget {
  final StoreStatus status;

  const _StoreStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      StoreStatus.active => AppColors.success,
      StoreStatus.inactive => AppColors.warning,
      StoreStatus.closed => AppColors.textMuted,
      StoreStatus.unknown => AppColors.info,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }
}
