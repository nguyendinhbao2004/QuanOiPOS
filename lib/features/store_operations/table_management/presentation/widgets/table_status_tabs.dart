import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import '../controllers/table_management_state.dart';

class TableStatusTabs extends StatelessWidget {
  final TableStatusFilter selectedFilter;
  final int availableCount;
  final ValueChanged<TableStatusFilter> onChanged;

  const TableStatusTabs({
    super.key,
    required this.selectedFilter,
    required this.availableCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Row(
        children: [
          _StatusTab(
            controlKey: const Key('table_status_filter_all'),
            label: 'Tất cả',
            isSelected: selectedFilter == TableStatusFilter.all,
            onTap: () => onChanged(TableStatusFilter.all),
          ),
          _StatusTab(
            controlKey: const Key('table_status_filter_occupied'),
            label: 'Đang dùng',
            isSelected: selectedFilter == TableStatusFilter.occupied,
            onTap: () => onChanged(TableStatusFilter.occupied),
          ),
          _StatusTab(
            controlKey: const Key('table_status_filter_available'),
            label: 'Còn trống',
            isSelected: selectedFilter == TableStatusFilter.available,
            badgeCount: availableCount,
            onTap: () => onChanged(TableStatusFilter.available),
          ),
        ],
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final Key controlKey;
  final String label;
  final bool isSelected;
  final int? badgeCount;
  final VoidCallback onTap;

  const _StatusTab({
    required this.controlKey,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        key: controlKey,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 3 : 1,
              ),
              left: const BorderSide(color: AppColors.border),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (badgeCount != null && badgeCount! > 0)
                Positioned(
                  top: -4,
                  right: AppConstants.spacingMd,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    ),
                    child: Text(
                      badgeCount!.toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
