import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import '../../domain/entities/area.dart';
import '../../domain/entities/dining_table.dart';
import '../../domain/entities/table_status.dart';
import 'add_table_tile.dart';
import 'table_tile.dart';

class AreaTableSection extends StatelessWidget {
  final Area area;
  final List<DiningTable> tables;
  final bool canViewTables;
  final bool canCreateTable;
  final ValueChanged<Area> onAddTableTap;
  final ValueChanged<DiningTable> onTableTap;

  const AreaTableSection({
    super.key,
    required this.area,
    required this.tables,
    required this.canViewTables,
    required this.canCreateTable,
    required this.onAddTableTap,
    required this.onTableTap,
  });

  @override
  Widget build(BuildContext context) {
    final availableCount = tables
        .where((table) => table.status == TableStatus.available)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                area.name,
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text('Còn trống: $availableCount', style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: AppConstants.spacingSm),
        if (!canViewTables)
          const _PermissionHint()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final int crossAxisCount;
              final double childAspectRatio;

              if (width >= 800) {
                crossAxisCount = 4;
                childAspectRatio = 1.3;
              } else if (width >= 500) {
                crossAxisCount = 3;
                childAspectRatio = 1.25;
              } else {
                crossAxisCount = 2;
                childAspectRatio = 1.22;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: AppConstants.spacingMd,
                  crossAxisSpacing: AppConstants.spacingMd,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: tables.length + 1,
                itemBuilder: (context, index) {
                  if (index == tables.length) {
                    return AddTableTile(
                      isEnabled: canCreateTable,
                      onTap: () => onAddTableTap(area),
                    );
                  }

                  final table = tables[index];
                  return TableTile(table: table, onTap: () => onTableTap(table));
                },
              );
            },
          ),
      ],
    );
  }
}

class _PermissionHint extends StatelessWidget {
  const _PermissionHint();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          children: [
            const Icon(
              Icons.visibility_off_outlined,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Text(
                'Bạn chưa có quyền xem danh sách bàn',
                style: AppTextStyles.bodySm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
