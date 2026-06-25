import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_permission_codes.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../inventory_stock/domain/entities/inventory_stock.dart';
import '../../inventory_stock/presentation/controllers/inventory_stock_notifiers.dart';
import '../../inventory_stock/presentation/controllers/inventory_stock_state.dart';
import '../../inventory_stock/presentation/providers/inventory_stock_providers.dart';

class StoreInventoryStockPage extends ConsumerWidget {
  final int storeId;

  const StoreInventoryStockPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));
    final canUseInventory = accessState.can(AppPermissionCodes.inventoryView);
    final canCreateInventory = accessState.can(
      AppPermissionCodes.inventoryImport,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton:
          accessState.status == StoreAccessStatus.ready && canCreateInventory
          ? FloatingActionButton(
              onPressed: () => _showInventoryStockCreateMenu(context, storeId),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              tooltip: 'Tạo nhanh',
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
          StoreAccessStatus.ready =>
            canUseInventory
                ? _ReadyView(storeId: storeId)
                : _BlockedView(
                    icon: Icons.lock_outline_rounded,
                    title: 'Bạn chưa có quyền xem tồn kho',
                    message:
                        'Vui lòng liên hệ quản lý cửa hàng để được cấp quyền.',
                    actionLabel: 'Về quản lý kho',
                    onAction: () => context.goNamed(
                      RouteNames.storeInventoryManagement,
                      pathParameters: {'storeId': storeId.toString()},
                    ),
                  ),
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
    final args = InventoryStockListArgs(storeId: storeId);
    final state = ref.watch(inventoryStockListNotifierProvider(args));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _InventoryStockHeader(storeId: storeId, args: args),
            _InventoryStockTypeTabs(args: args, selected: state.selectedType),
            _InventoryStockFilters(args: args, state: state),
            _InventoryStockSummary(
              totalQuantity: state.visibleQuantityTotal,
              totalValue: state.visibleValueTotal,
            ),
            Expanded(
              child: _InventoryStockList(storeId: storeId, state: state),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryStockHeader extends StatelessWidget {
  final int storeId;
  final InventoryStockListArgs args;

  const _InventoryStockHeader({required this.storeId, required this.args});

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
          Expanded(child: _InventorySearchField(args: args)),
          const SizedBox(width: AppConstants.spacingXs),
          IconButton(
            tooltip: 'Kho',
            icon: const Icon(Icons.warehouse_outlined),
            color: AppColors.textSecondary,
            onPressed: () => _showComingSoon(context, 'Kho'),
          ),
        ],
      ),
    );
  }
}

class _InventorySearchField extends ConsumerWidget {
  final InventoryStockListArgs args;

  const _InventorySearchField({required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 44,
      child: TextField(
        key: const Key('inventory_stock_search_field'),
        onChanged: (value) => ref
            .read(inventoryStockListNotifierProvider(args).notifier)
            .setSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Tìm tên tồn kho...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            tooltip: 'Quét mã',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => _showComingSoon(context, 'Quét mã'),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingSm,
            vertical: AppConstants.spacingSm,
          ),
        ),
      ),
    );
  }
}

class _InventoryStockTypeTabs extends ConsumerWidget {
  final InventoryStockListArgs args;
  final InventoryStockItemType selected;

  const _InventoryStockTypeTabs({required this.args, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingXs,
        AppConstants.spacingMd,
        AppConstants.spacingSm,
      ),
      child: SegmentedButton<InventoryStockItemType>(
        segments: const [
          ButtonSegment(
            value: InventoryStockItemType.product,
            icon: Icon(Icons.inventory_2_outlined),
            label: Text('Sản phẩm'),
          ),
          ButtonSegment(
            value: InventoryStockItemType.ingredient,
            icon: Icon(Icons.grass_outlined),
            label: Text('Nguyên liệu'),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (values) => ref
            .read(inventoryStockListNotifierProvider(args).notifier)
            .setType(values.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStateProperty.all(AppTextStyles.labelSm),
        ),
      ),
    );
  }
}

class _InventoryStockFilters extends StatelessWidget {
  final InventoryStockListArgs args;
  final InventoryStockListState state;

  const _InventoryStockFilters({required this.args, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterChipButton(
              label: 'Danh mục',
              onPressed: () => _showComingSoon(context, 'Danh mục'),
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: _StatusFilterButton(
              args: args,
              selected: state.selectedStatus,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: _FilterChipButton(
              label: 'Sắp xếp',
              onPressed: () => _showComingSoon(context, 'Sắp xếp'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterButton extends ConsumerWidget {
  final InventoryStockListArgs args;
  final InventoryStockStatus selected;

  const _StatusFilterButton({required this.args, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _FilterChipButton(
      label: selected.label,
      onPressed: () => _showStatusFilter(context, ref, args),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _FilterChipButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
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

class _InventoryStockSummary extends StatelessWidget {
  final double totalQuantity;
  final double totalValue;

  const _InventoryStockSummary({
    required this.totalQuantity,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingXs,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryText(
              label: 'Số lượng',
              value: _formatQuantity(totalQuantity),
            ),
          ),
          Expanded(
            child: _SummaryText(
              label: 'Giá trị tồn',
              value: _formatMoney(totalValue),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryText extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryStockList extends StatelessWidget {
  final int storeId;
  final InventoryStockListState state;

  const _InventoryStockList({required this.storeId, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == InventoryStockLoadStatus.loading ||
        state.status == InventoryStockLoadStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == InventoryStockLoadStatus.error) {
      return _InventoryStockError(
        args: InventoryStockListArgs(storeId: storeId),
        state: state,
      );
    }

    final items = state.visibleItems;
    if (items.isEmpty) {
      final message = state.searchQuery.trim().isEmpty
          ? 'Chưa có dữ liệu tồn kho.'
          : 'Không tìm thấy mặt hàng phù hợp.';
      return _EmptyInventoryStock(message: message);
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingXxl),
      itemBuilder: (context, index) {
        return _InventoryStockTile(item: items[index]);
      },
      separatorBuilder: (context, index) => const Divider(
        indent: AppConstants.spacingMd,
        endIndent: AppConstants.spacingMd,
      ),
      itemCount: items.length,
    );
  }
}

class _InventoryStockError extends ConsumerWidget {
  final InventoryStockListArgs args;
  final InventoryStockListState state;

  const _InventoryStockError({required this.args, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BlockedView(
      icon: Icons.error_outline_rounded,
      title: 'Không thể tải tồn kho',
      message: state.errorMessage ?? 'Vui lòng thử lại sau.',
      actionLabel: 'Thử lại',
      onAction: () =>
          ref.read(inventoryStockListNotifierProvider(args).notifier).load(),
    );
  }
}

class _EmptyInventoryStock extends StatelessWidget {
  final String message;

  const _EmptyInventoryStock({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.textMuted,
              size: 44,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryStockTile extends StatelessWidget {
  final InventoryStockItem item;

  const _InventoryStockTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isOutOfStock
        ? AppColors.error
        : item.isLowStock
        ? AppColors.warning
        : AppColors.textSecondary;
    final statusLabel = item.isOutOfStock
        ? 'Hết hàng'
        : item.isLowStock
        ? 'Sắp hết'
        : item.isTrackInventory
        ? 'Đang theo dõi'
        : 'Không theo dõi';

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () => _showMovementSheet(context, item),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          child: Row(
            children: [
              _ProductThumbnail(type: item.type),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _itemSubtitle(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Kho: ${_formatQuantity(item.quantity)} / ${_formatQuantity(item.minimumStock)} ${item.displayUnit}',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    statusLabel,
                    style: AppTextStyles.bodySm.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
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

class _ProductThumbnail extends StatelessWidget {
  final InventoryStockItemType type;

  const _ProductThumbnail({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Icon(
        type == InventoryStockItemType.product
            ? Icons.inventory_2_outlined
            : Icons.grass_outlined,
        color: AppColors.textDisabled,
        size: 24,
      ),
    );
  }
}

class _MovementSheet extends ConsumerWidget {
  final InventoryStockItem item;

  const _MovementSheet({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = InventoryMovementArgs(type: item.type, itemId: item.id);
    final state = ref.watch(inventoryMovementNotifierProvider(args));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingMd,
          AppConstants.spacingMd,
          AppConstants.spacingMd,
          AppConstants.spacingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              'Lịch sử biến động 30 ngày gần nhất',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            _MovementSheetBody(args: args, state: state),
          ],
        ),
      ),
    );
  }
}

class _MovementSheetBody extends ConsumerWidget {
  final InventoryMovementArgs args;
  final InventoryMovementState state;

  const _MovementSheetBody({required this.args, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.status == InventoryStockLoadStatus.loading ||
        state.status == InventoryStockLoadStatus.initial) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == InventoryStockLoadStatus.error) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage ?? 'Không thể tải lịch sử tồn kho.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySm,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              OutlinedButton(
                onPressed: () => ref
                    .read(inventoryMovementNotifierProvider(args).notifier)
                    .load(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.movements.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Chưa có biến động trong 30 ngày gần nhất.',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: state.movements.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) =>
            _MovementTile(movement: state.movements[index]),
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final InventoryMovement movement;

  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isImport = movement.type.toLowerCase() == 'import';
    final quantityPrefix = isImport ? '+' : '-';
    final color = isImport ? AppColors.success : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      child: Row(
        children: [
          Icon(
            isImport ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.reason.isEmpty ? movement.type : movement.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _movementDescription(movement),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyXs.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$quantityPrefix${_formatQuantity(movement.quantity)}',
                style: AppTextStyles.label.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _formatDateTime(movement.occurredAt),
                style: AppTextStyles.bodyXs.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
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

enum _InventoryStockCreateAction {
  barcode(
    icon: Icons.print_outlined,
    label: 'In tem mã vạch',
    key: Key('inventory_stock_print_barcode_action'),
  ),
  exportProduct(
    icon: Icons.upload_rounded,
    label: 'Tạo xuất hàng',
    key: Key('inventory_stock_create_export_action'),
  ),
  check(
    icon: Icons.fact_check_outlined,
    label: 'Tạo kiểm kho',
    key: Key('inventory_stock_create_check_action'),
  ),
  importProduct(
    icon: Icons.download_rounded,
    label: 'Tạo nhập hàng',
    key: Key('inventory_stock_create_import_action'),
  ),
  product(
    icon: Icons.inventory_2_outlined,
    label: 'Tạo sản phẩm',
    key: Key('inventory_stock_create_product_action'),
  );

  final IconData icon;
  final String label;
  final Key key;

  const _InventoryStockCreateAction({
    required this.icon,
    required this.label,
    required this.key,
  });
}

Future<void> _showStatusFilter(
  BuildContext context,
  WidgetRef ref,
  InventoryStockListArgs args,
) async {
  final selected = await showModalBottomSheet<InventoryStockStatus>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Trạng thái tồn kho')),
          for (final status in InventoryStockStatus.values)
            ListTile(
              title: Text(status.label),
              onTap: () => Navigator.of(context).pop(status),
            ),
        ],
      ),
    ),
  );

  if (selected == null) return;
  await ref
      .read(inventoryStockListNotifierProvider(args).notifier)
      .setStatus(selected);
}

Future<void> _showMovementSheet(
  BuildContext context,
  InventoryStockItem item,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _MovementSheet(item: item),
  );
}

Future<void> _showInventoryStockCreateMenu(
  BuildContext context,
  int storeId,
) async {
  final selectedAction = await showGeneralDialog<_InventoryStockCreateAction>(
    context: context,
    barrierColor: AppColors.overlay,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: AppConstants.animFast,
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _InventoryStockCreateMenuOverlay();
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
    case _InventoryStockCreateAction.barcode:
      _showComingSoon(context, 'In tem mã vạch');
    case _InventoryStockCreateAction.exportProduct:
      context.goNamed(
        RouteNames.storeInventoryExportProducts,
        pathParameters: {'storeId': storeId.toString()},
      );
    case _InventoryStockCreateAction.check:
      context.goNamed(
        RouteNames.storeInventoryCheckCreate,
        pathParameters: {'storeId': storeId.toString()},
      );
    case _InventoryStockCreateAction.importProduct:
      context.goNamed(
        RouteNames.storeInventoryImportProducts,
        pathParameters: {'storeId': storeId.toString()},
      );
    case _InventoryStockCreateAction.product:
      context.goNamed(
        RouteNames.storeProductCreate,
        pathParameters: {'storeId': storeId.toString()},
      );
  }
}

class _InventoryStockCreateMenuOverlay extends StatelessWidget {
  const _InventoryStockCreateMenuOverlay();

  static const double _pageMaxWidth = 560;
  static const double _menuWidth = 240;
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
                  key: const Key('inventory_stock_create_menu_backdrop'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                right: rightInset,
                bottom: bottomInset,
                child: const _InventoryStockCreateMenu(width: _menuWidth),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InventoryStockCreateMenu extends StatelessWidget {
  final double width;

  const _InventoryStockCreateMenu({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('inventory_stock_create_menu'),
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
          for (final action in _InventoryStockCreateAction.values)
            _InventoryStockCreateMenuItem(action: action),
        ],
      ),
    );
  }
}

class _InventoryStockCreateMenuItem extends StatelessWidget {
  final _InventoryStockCreateAction action;

  const _InventoryStockCreateMenuItem({required this.action});

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

String _itemSubtitle(InventoryStockItem item) {
  if (item.type == InventoryStockItemType.ingredient) {
    return 'Nguyên liệu • Đơn vị ${item.displayUnit}';
  }
  final mode = item.inventoryDeductionMode;
  return mode == null || mode.isEmpty ? 'Sản phẩm' : 'Sản phẩm • $mode';
}

String _movementDescription(InventoryMovement movement) {
  final parts = <String>[
    if (movement.note != null) movement.note!,
    if (movement.destinationName != null) 'Đến ${movement.destinationName}',
    if (movement.shortageQuantity > 0)
      'Thiếu ${_formatQuantity(movement.shortageQuantity)}',
  ];
  if (parts.isEmpty) return 'Giá trị ${_formatMoney(movement.totalCost)}';
  return parts.join(' • ');
}

String _formatQuantity(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _formatMoney(double value) =>
    NumberFormat.decimalPattern('vi_VN').format(value.round());

String _formatDateTime(DateTime? value) {
  if (value == null) return '—';
  return DateFormat('dd/MM HH:mm').format(value.toLocal());
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$feature sẽ được triển khai sau')));
}
