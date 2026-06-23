import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../inventory_documents/domain/entities/inventory_document.dart';
import '../../inventory_documents/presentation/controllers/inventory_document_notifiers.dart';
import '../../inventory_documents/presentation/controllers/inventory_document_state.dart';
import '../../inventory_documents/presentation/providers/inventory_document_providers.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../providers/store_inventory_export_mock_provider.dart';

class StoreInventoryExportPage extends ConsumerWidget {
  final int storeId;

  const StoreInventoryExportPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: accessState.status == StoreAccessStatus.ready
          ? FloatingActionButton(
              key: const Key('inventory_export_create_action'),
              onPressed: () => context.goNamed(
                RouteNames.storeInventoryExportDraft,
                pathParameters: {'storeId': '$storeId'},
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              tooltip: 'Tạo xuất hàng',
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: switch (accessState.status) {
          StoreAccessStatus.initial ||
          StoreAccessStatus.loading => const _LoadingView(),
          StoreAccessStatus.forbidden => _BlockedView(
            icon: Icons.lock_outline_rounded,
            title: 'Không có quyền truy cập',
            message:
                accessState.errorMessage ??
                'Tài khoản của bạn không có quyền truy cập cửa hàng này.',
            actionLabel: 'Về danh sách cửa hàng',
            onAction: () => context.goNamed(RouteNames.myStores),
          ),
          StoreAccessStatus.error => _BlockedView(
            icon: Icons.error_outline_rounded,
            title: 'Không thể tải thông tin cửa hàng',
            message: accessState.errorMessage ?? 'Vui lòng thử lại sau.',
            actionLabel: 'Thử lại',
            onAction: () => ref
                .read(storeAccessNotifierProvider(storeId).notifier)
                .loadAccess(),
          ),
          StoreAccessStatus.ready => _ReadyView(storeId: storeId),
        },
      ),
    );
  }
}

class _ReadyView extends ConsumerWidget {
  final int storeId;

  const _ReadyView({required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listArgs = InventoryDocumentListArgs(
      storeId: storeId,
      type: InventoryDocumentType.manualIssue,
    );
    final state = ref.watch(inventoryDocumentListNotifierProvider(listArgs));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _InventoryExportHeader(storeId: storeId),
            _InventoryExportTabs(listArgs, state.selectedStatus),
            _InventoryExportFilters(listArgs),
            Expanded(child: _InventoryExportLedger(storeId, state)),
          ],
        ),
      ),
    );
  }
}

class _InventoryExportHeader extends StatelessWidget {
  final int storeId;

  const _InventoryExportHeader({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingSm,
        AppConstants.spacingSm,
        AppConstants.spacingSm,
        AppConstants.spacingXs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.goNamed(
              RouteNames.storeInventoryManagement,
              pathParameters: {'storeId': storeId.toString()},
            ),
          ),
          Expanded(
            child: Text(
              'Sổ xuất hàng',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Tìm kiếm',
            icon: const Icon(Icons.search_rounded),
            color: AppColors.textSecondary,
            onPressed: () => _showComingSoon(context, 'Tìm kiếm xuất hàng'),
          ),
          IconButton(
            tooltip: 'Tải xuống',
            icon: const Icon(Icons.file_download_outlined),
            color: AppColors.textSecondary,
            onPressed: () => _showComingSoon(context, 'Tải sổ xuất hàng'),
          ),
        ],
      ),
    );
  }
}

class _InventoryExportTabs extends ConsumerWidget {
  final InventoryDocumentListArgs args;
  final InventoryDocumentStatus? selected;
  const _InventoryExportTabs(this.args, this.selected);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = <InventoryDocumentStatus?>[
      null,
      ...InventoryDocumentStatus.values,
    ];
    return Container(
      color: AppColors.surface,
      child: Row(
        children: [
          for (final status in tabs)
            Expanded(
              child: _InventoryExportTab(
                label: status?.label ?? 'Tất cả',
                isSelected: status == selected,
                onTap: () => ref
                    .read(inventoryDocumentListNotifierProvider(args).notifier)
                    .setStatus(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _InventoryExportTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _InventoryExportTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2.5 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSm.copyWith(
            color: color,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _InventoryExportFilters extends ConsumerWidget {
  final InventoryDocumentListArgs args;
  const _InventoryExportFilters(this.args);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryDocumentListNotifierProvider(args));
    final label = state.from == null
        ? 'Tháng này'
        : '${state.from!.day}/${state.from!.month} - ${state.to!.day}/${state.to!.month}';
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingMd,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 124,
            child: _FilterButton(
              label: label,
              onPressed: () => _showDateFilter(context, ref, args),
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          const SizedBox(width: 124, child: _FilterButton(label: 'Phân loại')),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _FilterButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () => _showComingSoon(context, label),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm),
        textStyle: AppTextStyles.labelSm,
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.borderStrong),
      ),
    );
  }
}

class _InventoryExportLedger extends StatelessWidget {
  final int storeId;
  final InventoryDocumentListState state;
  const _InventoryExportLedger(this.storeId, this.state);

  @override
  Widget build(BuildContext context) {
    if (state.status == InventoryDocumentLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == InventoryDocumentLoadStatus.error) {
      return Center(child: Text(state.errorMessage ?? 'Không thể tải sổ xuất'));
    }
    final items = state.page?.items ?? const [];
    if (items.isEmpty) {
      return const Center(child: Text('Chưa có phiếu xuất hàng.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        0,
        AppConstants.spacingMd,
        AppConstants.spacingXxl + AppConstants.spacingLg,
      ),
      itemBuilder: (context, index) {
        return _InventoryExportDocumentCard(
          storeId: storeId,
          item: items[index],
        );
      },
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.spacingSm),
      itemCount: items.length,
    );
  }
}

class _InventoryExportDocumentCard extends StatelessWidget {
  final int storeId;
  final InventoryDocumentSummary item;

  const _InventoryExportDocumentCard({
    required this.storeId,
    required this.item,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
    child: InkWell(
      onTap: () => context.goNamed(
        RouteNames.storeInventoryExportDetail,
        pathParameters: {'storeId': '$storeId', 'documentId': '${item.id}'},
      ),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.documentCode,
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        item.createdAt?.toLocal().toString().substring(0, 16) ??
                            '—',
                        style: AppTextStyles.bodyXs,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.status.label,
                      style: AppTextStyles.labelXs.copyWith(
                        color: item.status == InventoryDocumentStatus.completed
                            ? AppColors.success
                            : item.status == InventoryDocumentStatus.cancelled
                            ? AppColors.textMuted
                            : AppColors.warning,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Tạo bởi ${item.createdBy?.displayName ?? '—'}',
                      style: AppTextStyles.bodyXs,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            const Divider(height: 1),
            const SizedBox(height: AppConstants.spacingSm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.note ?? 'Không có ghi chú',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyXs.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  item.totalAmount.toStringAsFixed(0),
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ignore: unused_element
class _InventoryExportCard extends StatelessWidget {
  final StoreInventoryExportMockItem item;

  const _InventoryExportCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: () => _showComingSoon(context, item.code),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.code,
                          style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        Text(item.createdAtText, style: AppTextStyles.bodyXs),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.status,
                        style: AppTextStyles.labelXs.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        'Tạo bởi ${item.creatorName}',
                        style: AppTextStyles.bodyXs,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingSm),
              const Divider(height: 1),
              const SizedBox(height: AppConstants.spacingSm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tổng cộng',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    item.totalText,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _BlockedView({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 44),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              title,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

enum _InventoryExportCreateAction {
  product(
    icon: Icons.inventory_2_outlined,
    label: 'Xuất sản phẩm',
    key: Key('inventory_export_create_product_action'),
  ),
  ingredient(
    icon: Icons.kitchen_outlined,
    label: 'Xuất nguyên liệu',
    key: Key('inventory_export_create_ingredient_action'),
  ),
  supplementIngredient(
    icon: Icons.add_box_outlined,
    label: 'Bổ sung nguyên vật liệu',
    key: Key('inventory_export_supplement_ingredient_action'),
  );

  final IconData icon;
  final String label;
  final Key key;

  const _InventoryExportCreateAction({
    required this.icon,
    required this.label,
    required this.key,
  });
}

// ignore: unused_element
Future<void> _showInventoryExportCreateMenu(
  BuildContext context,
  int storeId,
) async {
  final selectedAction = await showGeneralDialog<_InventoryExportCreateAction>(
    context: context,
    barrierColor: AppColors.overlay,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: AppConstants.animFast,
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _InventoryExportCreateMenuOverlay();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );

  if (selectedAction == null || !context.mounted) {
    return;
  }

  switch (selectedAction) {
    case _InventoryExportCreateAction.product:
      context.goNamed(
        RouteNames.storeInventoryExportProducts,
        pathParameters: {'storeId': storeId.toString()},
      );
    case _InventoryExportCreateAction.ingredient:
      context.goNamed(
        RouteNames.storeInventoryExportIngredients,
        pathParameters: {'storeId': storeId.toString()},
      );
    case _InventoryExportCreateAction.supplementIngredient:
      context.goNamed(
        RouteNames.storeInventoryExportSupplementMaterials,
        pathParameters: {'storeId': storeId.toString()},
      );
  }
}

class _InventoryExportCreateMenuOverlay extends StatelessWidget {
  const _InventoryExportCreateMenuOverlay();

  static const double _pageMaxWidth = 560;
  static const double _menuWidth = 244;
  static const double _fabClearance = 88;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pageInset = constraints.maxWidth > _pageMaxWidth
              ? (constraints.maxWidth - _pageMaxWidth) / 2
              : 0.0;
          final rightInset = pageInset + AppConstants.spacingMd;
          final bottomInset =
              MediaQuery.paddingOf(context).bottom + _fabClearance;

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('inventory_export_create_menu_backdrop'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                right: rightInset,
                bottom: bottomInset,
                child: const _InventoryExportCreateMenu(width: _menuWidth),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InventoryExportCreateMenu extends StatelessWidget {
  final double width;

  const _InventoryExportCreateMenu({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('inventory_export_create_menu'),
      width: width,
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final action in _InventoryExportCreateAction.values)
            _InventoryExportCreateMenuItem(action: action),
        ],
      ),
    );
  }
}

class _InventoryExportCreateMenuItem extends StatelessWidget {
  final _InventoryExportCreateAction action;

  const _InventoryExportCreateMenuItem({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: action.key,
      onTap: () => Navigator.of(context).pop(action),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm,
        ),
        child: Row(
          children: [
            Icon(action.icon, color: AppColors.primary, size: 22),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$feature sẽ được triển khai sau')));
}

Future<void> _showDateFilter(
  BuildContext context,
  WidgetRef ref,
  InventoryDocumentListArgs args,
) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Lọc thời gian')),
          for (final item in const [
            'Hôm nay',
            'Tuần này',
            'Tháng này',
            'Khoảng thời gian',
          ])
            ListTile(
              title: Text(item),
              onTap: () => Navigator.pop(context, item),
            ),
        ],
      ),
    ),
  );
  if (choice == null) return;
  final now = DateTime.now();
  DateTime from;
  DateTime to;
  if (choice == 'Hôm nay') {
    from = DateTime(now.year, now.month, now.day);
    to = from.add(const Duration(days: 1));
  } else if (choice == 'Tuần này') {
    from = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    to = from.add(const Duration(days: 7));
  } else if (choice == 'Tháng này') {
    from = DateTime(now.year, now.month);
    to = DateTime(now.year, now.month + 1);
  } else {
    if (!context.mounted) return;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
    );
    if (range == null) return;
    from = DateTime(range.start.year, range.start.month, range.start.day);
    to = DateTime(range.end.year, range.end.month, range.end.day + 1);
  }
  await ref
      .read(inventoryDocumentListNotifierProvider(args).notifier)
      .setDateRange(from, to);
}
