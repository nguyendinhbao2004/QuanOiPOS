import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import '../../domain/entities/area.dart';

class AreaFilterChips extends StatelessWidget {
  final List<Area> areas;
  final int? selectedAreaId;
  final ValueChanged<int?> onSelected;

  const AreaFilterChips({
    super.key,
    required this.areas,
    required this.selectedAreaId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AreaChip(
            icon: Icons.grid_view_rounded,
            label: 'Tất cả',
            isSelected: selectedAreaId == null,
            onTap: () => onSelected(null),
          ),
          for (final area in areas) ...[
            const SizedBox(width: AppConstants.spacingSm),
            _AreaChip(
              label: area.name,
              isSelected: selectedAreaId == area.id,
              onTap: () => onSelected(area.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AreaChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm,
        ),
        foregroundColor: isSelected ? AppColors.primary : AppColors.textMuted,
        backgroundColor: isSelected
            ? AppColors.primaryLight
            : AppColors.surface,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.borderStrong,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        textStyle: AppTextStyles.labelSm,
      ),
    );
  }
}
