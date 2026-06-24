import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../domain/entities/kitchen_order_item.dart';
import '../controllers/kitchen_state.dart';
import '../providers/kitchen_providers.dart';

class KitchenPage extends ConsumerWidget {
  final int storeId;

  const KitchenPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));
    final accessContext = accessState.context;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: switch (accessState.status) {
          StoreAccessStatus.initial ||
          StoreAccessStatus.loading => const _LoadingView(),
          StoreAccessStatus.forbidden => _BlockedView(
            icon: Icons.lock_outline_rounded,
            title: 'Không có quyền truy cập',
            message:
                accessState.errorMessage ??
                'Tài khoản của bạn không có quyền truy cập cửa hàng này.',
            onBack: () => context.goNamed(RouteNames.myStores),
          ),
          StoreAccessStatus.error => _ErrorView(
            message:
                accessState.errorMessage ??
                'Không thể tải quyền truy cập cửa hàng',
            onRetry: () => ref
                .read(storeAccessNotifierProvider(storeId).notifier)
                .loadAccess(),
          ),
          StoreAccessStatus.ready =>
            accessContext == null
                ? _BlockedView(
                    icon: Icons.storefront_outlined,
                    title: 'Chưa có dữ liệu cửa hàng',
                    message: 'Vui lòng quay lại danh sách cửa hàng và thử lại.',
                    onBack: () => context.goNamed(RouteNames.myStores),
                  )
                : _KitchenReadyView(
                    access: KitchenAccess(
                      storeId: accessContext.store.id,
                      storeName: accessContext.store.storeName,
                      canManageKitchen: accessState.can(
                        AppPermissionCodes.kitchenAll,
                      ),
                    ),
                  ),
        },
      ),
    );
  }
}

class _KitchenReadyView extends ConsumerWidget {
  final KitchenAccess access;

  const _KitchenReadyView({required this.access});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!access.canManageKitchen) {
      return _BlockedView(
        icon: Icons.restaurant_menu_rounded,
        title: 'Bạn chưa có quyền dùng KDS',
        message:
            'Màn hình bếp cần quyền ${AppPermissionCodes.kitchenAll}. Vui lòng liên hệ quản trị viên cửa hàng.',
        onBack: () => context.goNamed(RouteNames.storeHome),
      );
    }

    final state = ref.watch(kitchenNotifierProvider(access));
    final notifier = ref.read(kitchenNotifierProvider(access).notifier);

    return Column(
      children: [
        _KitchenTopBar(
          access: access,
          onRefresh: () => notifier.load(refresh: true),
        ),
        _KitchenStatusBar(
          state: state,
          onStatusChanged: notifier.setStatusFilter,
          onModeChanged: notifier.setMode,
        ),
        if (state.isRefreshing) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: switch (state.status) {
            KitchenLoadStatus.initial ||
            KitchenLoadStatus.loading => const _LoadingView(),
            KitchenLoadStatus.forbidden => _BlockedView(
              icon: Icons.lock_outline_rounded,
              title: 'Bạn chưa có quyền dùng KDS',
              message:
                  state.errorMessage ?? 'Vui lòng kiểm tra lại phân quyền.',
              onBack: () => context.goNamed(RouteNames.storeHome),
            ),
            KitchenLoadStatus.error => _ErrorView(
              message: state.errorMessage ?? 'Không thể tải danh sách món bếp',
              onRetry: notifier.load,
            ),
            KitchenLoadStatus.ready => _KitchenBoard(
              state: state,
              onRefresh: () => notifier.load(refresh: true),
              onToggleSelection: notifier.toggleSelection,
              onUpdateStatus: (item, status) async {
                await _runItemAction(
                  context,
                  () => notifier.updateItemStatus(
                    orderItemId: item.orderItemId,
                    status: status,
                  ),
                  successMessage: status == KitchenOrderItemStatus.ready
                      ? 'Đã hoàn thành món'
                      : 'Đã chuyển sang đang làm',
                );
              },
              onCancel: (item) async {
                await _runItemAction(
                  context,
                  () => notifier.cancelItem(item.orderItemId),
                  successMessage: 'Đã hủy món',
                );
              },
              onUpdateItemsStatus: (items, status) async {
                await _runGroupedItemAction(
                  context,
                  () async {
                    var updated = 0;
                    for (final item in items) {
                      if (item.status == KitchenOrderItemStatus.ready ||
                          item.status == KitchenOrderItemStatus.cancelled) {
                        continue;
                      }
                      await notifier.updateItemStatus(
                        orderItemId: item.orderItemId,
                        status: status,
                      );
                      updated++;
                    }
                    return updated;
                  },
                  successMessage: (updated) =>
                      status == KitchenOrderItemStatus.ready
                      ? 'Đã hoàn thành $updated món'
                      : 'Đã chuyển $updated món sang đang làm',
                );
              },
              onCancelItems: (items) async {
                await _runGroupedItemAction(context, () async {
                  var updated = 0;
                  for (final item in items) {
                    if (item.status == KitchenOrderItemStatus.cancelled) {
                      continue;
                    }
                    await notifier.cancelItem(item.orderItemId);
                    updated++;
                  }
                  return updated;
                }, successMessage: (updated) => 'Đã hủy $updated món');
              },
              onPrepareSelected: () async {
                await _runBulkAction(context, () => notifier.prepareSelected());
              },
              onCompleteSelected: () async {
                await _runBulkAction(
                  context,
                  () => notifier.completeSelected(),
                );
              },
              onCompleteTable: (items) async {
                await _runTableAction(context, () async {
                  var updated = 0;
                  for (final item in items) {
                    if (item.status == KitchenOrderItemStatus.ready ||
                        item.status == KitchenOrderItemStatus.cancelled) {
                      continue;
                    }
                    await notifier.updateItemStatus(
                      orderItemId: item.orderItemId,
                      status: KitchenOrderItemStatus.ready,
                    );
                    updated++;
                  }
                  return updated;
                });
              },
              onCancelSelected: () async {
                await _runBulkAction(context, () => notifier.cancelSelected());
              },
              onClearSelection: notifier.clearSelection,
            ),
          },
        ),
      ],
    );
  }
}

class _KitchenTopBar extends StatelessWidget {
  final KitchenAccess access;
  final VoidCallback onRefresh;

  const _KitchenTopBar({required this.access, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm,
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Quay lại',
              onPressed: () => context.goNamed(RouteNames.storeHome),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'KDS Bếp Trung Tâm',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    access.storeName.isEmpty
                        ? 'Chi nhánh ${AppConstants.branchName}'
                        : access.storeName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _ClockPill(now: DateTime.now()),
            const SizedBox(width: AppConstants.spacingSm),
            IconButton(
              tooltip: 'Làm mới',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Cài đặt',
              onPressed: () =>
                  _showSnack(context, 'Cài đặt bếp sẽ được triển khai sau'),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitchenStatusBar extends StatelessWidget {
  final KitchenState state;
  final ValueChanged<KitchenOrderItemStatus> onStatusChanged;
  final ValueChanged<KitchenBoardMode> onModeChanged;

  const _KitchenStatusBar({
    required this.state,
    required this.onStatusChanged,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pendingCount = state.items
        .where((item) => item.status == KitchenOrderItemStatus.pending)
        .length;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderStrong)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingLg,
          AppConstants.spacingMd,
          AppConstants.spacingLg,
          AppConstants.spacingMd,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 860;
            final title = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Flexible(
                  child: Text(
                    _statusTitle(state.filter.status),
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                _CountBadge(count: pendingCount),
              ],
            );

            final filters = Wrap(
              spacing: AppConstants.spacingSm,
              runSpacing: AppConstants.spacingSm,
              alignment: WrapAlignment.end,
              children: [
                _StatusChip(
                  label: 'Chờ',
                  isSelected:
                      state.filter.status == KitchenOrderItemStatus.pending,
                  onTap: () => onStatusChanged(KitchenOrderItemStatus.pending),
                ),
                _StatusChip(
                  label: 'Đang làm',
                  isSelected:
                      state.filter.status == KitchenOrderItemStatus.preparing,
                  onTap: () =>
                      onStatusChanged(KitchenOrderItemStatus.preparing),
                ),
                _StatusChip(
                  label: 'Đã xong',
                  isSelected:
                      state.filter.status == KitchenOrderItemStatus.ready,
                  onTap: () => onStatusChanged(KitchenOrderItemStatus.ready),
                ),
                _ModeSegment(value: state.mode, onChanged: onModeChanged),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: AppConstants.spacingMd),
                  filters,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: title),
                filters,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KitchenBoard extends StatelessWidget {
  final KitchenState state;
  final RefreshCallback onRefresh;
  final ValueChanged<int> onToggleSelection;
  final Future<void> Function(KitchenOrderItem, KitchenOrderItemStatus)
  onUpdateStatus;
  final Future<void> Function(KitchenOrderItem) onCancel;
  final Future<void> Function(List<KitchenOrderItem>, KitchenOrderItemStatus)
  onUpdateItemsStatus;
  final Future<void> Function(List<KitchenOrderItem>) onCancelItems;
  final Future<void> Function() onPrepareSelected;
  final Future<void> Function() onCompleteSelected;
  final Future<void> Function(List<KitchenOrderItem>) onCompleteTable;
  final Future<void> Function() onCancelSelected;
  final VoidCallback onClearSelection;

  const _KitchenBoard({
    required this.state,
    required this.onRefresh,
    required this.onToggleSelection,
    required this.onUpdateStatus,
    required this.onCancel,
    required this.onUpdateItemsStatus,
    required this.onCancelItems,
    required this.onPrepareSelected,
    required this.onCompleteSelected,
    required this.onCompleteTable,
    required this.onCancelSelected,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final items = state.visibleItems;

    return ColoredBox(
      color: AppColors.sidebar,
      child: Column(
        children: [
          if (state.selectedItemIds.isNotEmpty)
            _BulkActionBar(
              selectedCount: state.selectedItemIds.length,
              isProcessing: state.isBulkProcessing,
              onPrepare: onPrepareSelected,
              onComplete: onCompleteSelected,
              onCancel: onCancelSelected,
              onClear: onClearSelection,
            ),
          Expanded(
            child: items.isEmpty
                ? _EmptyView(status: state.filter.status, onRefresh: onRefresh)
                : state.mode == KitchenBoardMode.byTable
                ? _KitchenTableBoard(
                    items: items,
                    processingItemIds: state.processingItemIds,
                    onRefresh: onRefresh,
                    onUpdateStatus: onUpdateItemsStatus,
                    onCancel: onCancelItems,
                    onCompleteTable: onCompleteTable,
                  )
                : RefreshIndicator(
                    onRefresh: onRefresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.spacingLg,
                        AppConstants.spacingMd,
                        AppConstants.spacingLg,
                        AppConstants.spacingXxl,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _KitchenOrderCard(
                          item: item,
                          isSelected: state.selectedItemIds.contains(
                            item.orderItemId,
                          ),
                          isProcessing: state.processingItemIds.contains(
                            item.orderItemId,
                          ),
                          onSelected: () => onToggleSelection(item.orderItemId),
                          onUpdateStatus: (status) =>
                              onUpdateStatus(item, status),
                          onCancel: () => onCancel(item),
                        );
                      },
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppConstants.spacingMd),
                      itemCount: items.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KitchenTableBoard extends StatelessWidget {
  final List<KitchenOrderItem> items;
  final Set<int> processingItemIds;
  final RefreshCallback onRefresh;
  final Future<void> Function(List<KitchenOrderItem>, KitchenOrderItemStatus)
  onUpdateStatus;
  final Future<void> Function(List<KitchenOrderItem>) onCancel;
  final Future<void> Function(List<KitchenOrderItem>) onCompleteTable;

  const _KitchenTableBoard({
    required this.items,
    required this.processingItemIds,
    required this.onRefresh,
    required this.onUpdateStatus,
    required this.onCancel,
    required this.onCompleteTable,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _groupItemsByTable(items);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingLg,
          AppConstants.spacingMd,
          AppConstants.spacingLg,
          AppConstants.spacingXxl,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1180
                ? 3
                : width >= 760
                ? 2
                : 1;
            const gap = AppConstants.spacingMd;
            final cardWidth = (width - (gap * (columns - 1))) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final group in groups)
                  SizedBox(
                    width: cardWidth,
                    child: _KitchenTableGroupCard(
                      group: group,
                      processingItemIds: processingItemIds,
                      onUpdateStatus: onUpdateStatus,
                      onCancel: onCancel,
                      onCompleteTable: () => onCompleteTable(group.items),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KitchenTableGroupCard extends StatelessWidget {
  final _KitchenTableGroup group;
  final Set<int> processingItemIds;
  final Future<void> Function(List<KitchenOrderItem>, KitchenOrderItemStatus)
  onUpdateStatus;
  final Future<void> Function(List<KitchenOrderItem>) onCancel;
  final VoidCallback onCompleteTable;

  const _KitchenTableGroupCard({
    required this.group,
    required this.processingItemIds,
    required this.onUpdateStatus,
    required this.onCancel,
    required this.onCompleteTable,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _tableGroupAccentColor(group);
    final headerBg = accent.withValues(alpha: 0.08);
    final bodyBg = accent.withValues(alpha: 0.04);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: Container(
        decoration: BoxDecoration(
          color: bodyBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: accent, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: headerBg,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
                vertical: AppConstants.spacingSm,
              ),
              child: Row(
                children: [
                  Icon(Icons.grid_view_rounded, color: accent, size: 20),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: Text(
                      group.title,
                      style: AppTextStyles.h4.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label: _waitingLabel(group.oldestItem),
                    color: accent,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (
                    var index = 0;
                    index < group.itemGroups.length;
                    index++
                  ) ...[
                    _KitchenTableItemRow(
                      group: group.itemGroups[index],
                      isProcessing: group.itemGroups[index].items.any(
                        (item) => processingItemIds.contains(item.orderItemId),
                      ),
                      onUpdateStatus: (status) =>
                          onUpdateStatus(group.itemGroups[index].items, status),
                      onCancel: () => onCancel(group.itemGroups[index].items),
                    ),
                    if (index != group.itemGroups.length - 1)
                      const Divider(height: AppConstants.spacingLg),
                  ],
                  const SizedBox(height: AppConstants.spacingMd),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: onCompleteTable,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('HOÀN THÀNH CẢ BÀN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitchenTableItemRow extends StatelessWidget {
  final _KitchenTableItemGroup group;
  final bool isProcessing;
  final ValueChanged<KitchenOrderItemStatus> onUpdateStatus;
  final VoidCallback onCancel;

  const _KitchenTableItemRow({
    required this.group,
    required this.isProcessing,
    required this.onUpdateStatus,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final item = group.item;
        final compact = constraints.maxWidth < 360;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.displayName,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Wrap(
              spacing: AppConstants.spacingSm,
              runSpacing: AppConstants.spacingXs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'SL: ${group.quantity}',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.note?.trim().isNotEmpty == true)
                  _InfoChip(
                    icon: Icons.sticky_note_2_outlined,
                    label: item.note!.trim(),
                    color: AppColors.warning,
                  ),
              ],
            ),
            if (item.toppings.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                item.toppings
                    .map(
                      (topping) =>
                          '${topping.toppingName} x${topping.quantity}',
                    )
                    .join(' · '),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );
        final actions = _KitchenTableItemActions(
          item: item,
          onUpdateStatus: onUpdateStatus,
          onCancel: onCancel,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              details,
              const SizedBox(height: AppConstants.spacingSm),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: details),
            const SizedBox(width: AppConstants.spacingSm),
            actions,
          ],
        );
      },
    );
  }
}

class _KitchenTableItemActions extends StatelessWidget {
  final KitchenOrderItem item;
  final ValueChanged<KitchenOrderItemStatus> onUpdateStatus;
  final VoidCallback onCancel;

  const _KitchenTableItemActions({
    required this.item,
    required this.onUpdateStatus,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppConstants.spacingXs,
      runSpacing: AppConstants.spacingXs,
      alignment: WrapAlignment.end,
      children: switch (item.status) {
        KitchenOrderItemStatus.pending => [
          _SmallIconButton(
            tooltip: 'Chuyển sang đang làm',
            icon: Icons.remove_rounded,
            color: AppColors.warning,
            onPressed: () => onUpdateStatus(KitchenOrderItemStatus.preparing),
          ),
          _SmallIconButton(
            tooltip: 'Hoàn thành món',
            label: 'Xong',
            color: AppColors.success,
            onPressed: () => onUpdateStatus(KitchenOrderItemStatus.ready),
          ),
        ],
        KitchenOrderItemStatus.preparing => [
          _SmallIconButton(
            tooltip: 'Hoàn thành món',
            label: 'Xong',
            color: AppColors.success,
            onPressed: () => onUpdateStatus(KitchenOrderItemStatus.ready),
          ),
          _SmallIconButton(
            tooltip: 'Hủy món',
            icon: Icons.close_rounded,
            color: AppColors.error,
            onPressed: onCancel,
          ),
        ],
        KitchenOrderItemStatus.ready => [
          _SmallIconButton(
            tooltip: 'Đã xong',
            label: 'Xong',
            color: AppColors.success,
            onPressed: null,
          ),
        ],
        KitchenOrderItemStatus.cancelled => [
          _SmallIconButton(
            tooltip: 'Đã hủy',
            icon: Icons.block_rounded,
            color: AppColors.error,
            onPressed: null,
          ),
        ],
      },
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final String tooltip;
  final IconData? icon;
  final String? label;
  final Color color;
  final VoidCallback? onPressed;

  const _SmallIconButton({
    required this.tooltip,
    this.icon,
    this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final child = label == null
        ? Icon(icon, size: 18)
        : Text(label!, style: AppTextStyles.labelSm);

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        height: 38,
        child: label == null
            ? OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.48)),
                  minimumSize: const Size(40, 38),
                  padding: EdgeInsets.zero,
                ),
                child: child,
              )
            : ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(68, 38),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSm,
                  ),
                ),
                child: child,
              ),
      ),
    );
  }
}

class _KitchenOrderCard extends StatelessWidget {
  final KitchenOrderItem item;
  final bool isSelected;
  final bool isProcessing;
  final VoidCallback onSelected;
  final ValueChanged<KitchenOrderItemStatus> onUpdateStatus;
  final VoidCallback onCancel;

  const _KitchenOrderCard({
    required this.item,
    required this.isSelected,
    required this.isProcessing,
    required this.onSelected,
    required this.onUpdateStatus,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final urgent = _waitingMinutes(item) >= 45;
    final borderColor = urgent ? AppColors.error : AppColors.borderStrong;
    final statusColor = _statusColor(item.status);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: InkWell(
        onLongPress: onSelected,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Container(
          decoration: BoxDecoration(
            color: urgent
                ? AppColors.error.withValues(alpha: 0.04)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border(
              left: BorderSide(color: borderColor, width: 6),
              top: BorderSide(color: borderColor),
              right: BorderSide(color: borderColor),
              bottom: BorderSide(color: borderColor),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final info = _CardInfo(item: item, urgent: urgent);
                final actions = _CardActions(
                  item: item,
                  statusColor: statusColor,
                  isProcessing: isProcessing,
                  onUpdateStatus: onUpdateStatus,
                  onCancel: onCancel,
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CardHeader(
                        item: item,
                        isSelected: isSelected,
                        onSelected: onSelected,
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                      info,
                      const SizedBox(height: AppConstants.spacingMd),
                      actions,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _CardHeader(
                            item: item,
                            isSelected: isSelected,
                            onSelected: onSelected,
                          ),
                          const SizedBox(height: AppConstants.spacingSm),
                          info,
                        ],
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingLg),
                    _QuantityBadge(quantity: 1, color: statusColor),
                    const SizedBox(width: AppConstants.spacingLg),
                    actions,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final KitchenOrderItem item;
  final bool isSelected;
  final VoidCallback onSelected;

  const _CardHeader({
    required this.item,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            item.displayName,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        IconButton(
          tooltip: isSelected ? 'Bỏ chọn' : 'Chọn món',
          onPressed: onSelected,
          icon: Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: isSelected ? AppColors.success : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _CardInfo extends StatelessWidget {
  final KitchenOrderItem item;
  final bool urgent;

  const _CardInfo({required this.item, required this.urgent});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _InfoChip(
        icon: Icons.table_restaurant_outlined,
        label: item.tableName.isEmpty ? 'Mang đi' : item.tableName,
        color: AppColors.info,
      ),
      _InfoChip(
        icon: Icons.schedule_rounded,
        label: _waitingLabel(item),
        color: urgent ? AppColors.error : AppColors.warning,
      ),
    ];

    if (item.note?.trim().isNotEmpty == true) {
      chips.add(
        _InfoChip(
          icon: Icons.sticky_note_2_outlined,
          label: item.note!.trim(),
          color: AppColors.warning,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppConstants.spacingSm,
          runSpacing: AppConstants.spacingSm,
          children: chips,
        ),
        if (item.toppings.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            item.toppings
                .map((topping) => '${topping.toppingName} x${topping.quantity}')
                .join(' · '),
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          'Mã: ORD-${item.orderId.toString().padLeft(3, '0')}',
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CardActions extends StatelessWidget {
  final KitchenOrderItem item;
  final Color statusColor;
  final bool isProcessing;
  final ValueChanged<KitchenOrderItemStatus> onUpdateStatus;
  final VoidCallback onCancel;

  const _CardActions({
    required this.item,
    required this.statusColor,
    required this.isProcessing,
    required this.onUpdateStatus,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return const SizedBox(
        width: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final buttons = switch (item.status) {
      KitchenOrderItemStatus.pending => [
        _ActionButton(
          label: 'Đang làm',
          icon: Icons.local_fire_department_outlined,
          isPrimary: false,
          color: AppColors.primary,
          onPressed: () => onUpdateStatus(KitchenOrderItemStatus.preparing),
        ),
        _ActionButton(
          label: 'Xong tất cả',
          icon: Icons.check_circle_outline_rounded,
          isPrimary: true,
          color: AppColors.success,
          onPressed: () => onUpdateStatus(KitchenOrderItemStatus.ready),
        ),
      ],
      KitchenOrderItemStatus.preparing => [
        _ActionButton(
          label: 'Hoàn thành',
          icon: Icons.check_circle_outline_rounded,
          isPrimary: true,
          color: AppColors.success,
          onPressed: () => onUpdateStatus(KitchenOrderItemStatus.ready),
        ),
        _ActionButton(
          label: 'Hủy',
          icon: Icons.cancel_outlined,
          isPrimary: false,
          color: AppColors.error,
          onPressed: onCancel,
        ),
      ],
      KitchenOrderItemStatus.ready => [
        _ActionButton(
          label: 'Đã xong',
          icon: Icons.done_all_rounded,
          isPrimary: true,
          color: statusColor,
          onPressed: null,
        ),
      ],
      KitchenOrderItemStatus.cancelled => [
        _ActionButton(
          label: 'Đã hủy',
          icon: Icons.block_rounded,
          isPrimary: false,
          color: statusColor,
          onPressed: null,
        ),
      ],
    };

    return Wrap(
      spacing: AppConstants.spacingSm,
      runSpacing: AppConstants.spacingSm,
      alignment: WrapAlignment.end,
      children: buttons,
    );
  }
}

class _BulkActionBar extends StatelessWidget {
  final int selectedCount;
  final bool isProcessing;
  final VoidCallback onPrepare;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onClear;

  const _BulkActionBar({
    required this.selectedCount,
    required this.isProcessing,
    required this.onPrepare,
    required this.onComplete,
    required this.onCancel,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLg,
        vertical: AppConstants.spacingSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Đã chọn $selectedCount món',
              style: AppTextStyles.labelSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isProcessing)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            _MiniButton(label: 'Đang làm', onPressed: onPrepare),
            const SizedBox(width: AppConstants.spacingSm),
            _MiniButton(label: 'Hoàn thành', onPressed: onComplete),
            const SizedBox(width: AppConstants.spacingSm),
            _MiniButton(label: 'Hủy', onPressed: onCancel),
          ],
          IconButton(
            tooltip: 'Bỏ chọn',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final KitchenBoardMode value;
  final ValueChanged<KitchenBoardMode> onChanged;

  const _ModeSegment({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<KitchenBoardMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: KitchenBoardMode.priority, label: Text('Ưu tiên')),
        ButtonSegment(
          value: KitchenBoardMode.byTable,
          label: Text('Theo phòng/bàn'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        textStyle: WidgetStateProperty.all(AppTextStyles.labelSm),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryLight,
      labelStyle: AppTextStyles.labelSm.copyWith(
        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final style = isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: color,
            minimumSize: const Size(160, 48),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            minimumSize: const Size(150, 48),
          );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppConstants.spacingSm),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    return SizedBox(
      width: isPrimary ? 178 : 164,
      child: isPrimary
          ? ElevatedButton(onPressed: onPressed, style: style, child: child)
          : OutlinedButton(onPressed: onPressed, style: style, child: child),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _MiniButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(96, 38),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
          ),
        ),
        child: Text(label, style: AppTextStyles.labelSm),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: AppConstants.spacingXs),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.labelSm.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  final int quantity;
  final Color color;

  const _QuantityBadge({required this.quantity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SL',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            quantity.toString(),
            style: AppTextStyles.h2.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Text(
        '$count order',
        style: AppTextStyles.labelXs.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ClockPill extends StatelessWidget {
  final DateTime now;

  const _ClockPill({required this.now});

  @override
  Widget build(BuildContext context) {
    final text = [
      now.hour.toString().padLeft(2, '0'),
      now.minute.toString().padLeft(2, '0'),
      now.second.toString().padLeft(2, '0'),
    ].join(':');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Text(
            text,
            style: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final KitchenOrderItemStatus? status;
  final RefreshCallback onRefresh;

  const _EmptyView({required this.status, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
          const Icon(
            Icons.restaurant_menu_rounded,
            color: AppColors.textMuted,
            size: 48,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Không có món ${_statusTitle(status).toLowerCase()}',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            'Kéo xuống để làm mới danh sách bếp.',
            style: AppTextStyles.bodySm,
            textAlign: TextAlign.center,
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
  final VoidCallback onBack;

  const _BlockedView({
    required this.icon,
    required this.title,
    required this.message,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 46),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              title,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w800),
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
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Quay lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 46,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Thử lại'),
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
    return const Center(child: CircularProgressIndicator());
  }
}

class _KitchenTableGroup {
  final String key;
  final String title;
  final List<KitchenOrderItem> items;

  const _KitchenTableGroup({
    required this.key,
    required this.title,
    required this.items,
  });

  KitchenOrderItem get oldestItem {
    return items.reduce((left, right) {
      final leftAt = left.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightAt = right.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return leftAt.isBefore(rightAt) ? left : right;
    });
  }

  List<_KitchenTableItemGroup> get itemGroups {
    final buckets = <String, List<KitchenOrderItem>>{};

    for (final item in items) {
      buckets.putIfAbsent(_tableItemGroupKey(item), () => []).add(item);
    }

    final groups = buckets.values.map((items) {
      final sortedItems = [...items]
        ..sort((a, b) {
          final left = a.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final right = b.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return left.compareTo(right);
        });
      return _KitchenTableItemGroup(items: sortedItems);
    }).toList();

    groups.sort((a, b) {
      final ordered = _compareNullableDate(a.item.orderedAt, b.item.orderedAt);
      if (ordered != 0) return ordered;
      return a.item.displayName.compareTo(b.item.displayName);
    });

    return groups;
  }
}

class _KitchenTableItemGroup {
  final List<KitchenOrderItem> items;

  const _KitchenTableItemGroup({required this.items});

  KitchenOrderItem get item => items.first;

  int get quantity => items.length;
}

String _tableItemGroupKey(KitchenOrderItem item) {
  final note = item.note?.trim().toLowerCase() ?? '';
  return [
    item.productId,
    item.variantId ?? 0,
    item.status.value,
    note,
    _toppingsGroupKey(item.toppings),
  ].join('|');
}

String _toppingsGroupKey(List<KitchenOrderItemTopping> toppings) {
  if (toppings.isEmpty) return '';
  final parts =
      toppings
          .map(
            (topping) => [
              topping.toppingId,
              topping.toppingName.trim().toLowerCase(),
              topping.quantity,
            ].join(':'),
          )
          .toList()
        ..sort();
  return parts.join(',');
}

int _compareNullableDate(DateTime? left, DateTime? right) {
  final leftAt = left ?? DateTime.fromMillisecondsSinceEpoch(0);
  final rightAt = right ?? DateTime.fromMillisecondsSinceEpoch(0);
  return leftAt.compareTo(rightAt);
}

List<_KitchenTableGroup> _groupItemsByTable(List<KitchenOrderItem> items) {
  final buckets = <String, List<KitchenOrderItem>>{};
  final titles = <String, String>{};

  for (final item in items) {
    final tableName = item.tableName.trim();
    final title = tableName.isEmpty ? 'Mang đi' : tableName;
    final key =
        '${item.tableSessionId ?? 0}:${item.tableId ?? 0}:${title.toLowerCase()}';
    buckets.putIfAbsent(key, () => []).add(item);
    titles[key] = title;
  }

  final groups = buckets.entries.map((entry) {
    final sortedItems = [...entry.value]
      ..sort((a, b) {
        final left = a.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return left.compareTo(right);
      });
    return _KitchenTableGroup(
      key: entry.key,
      title: titles[entry.key] ?? 'Mang đi',
      items: sortedItems,
    );
  }).toList();

  groups.sort((a, b) {
    final left =
        a.oldestItem.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final right =
        b.oldestItem.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final ordered = left.compareTo(right);
    if (ordered != 0) return ordered;
    return a.title.compareTo(b.title);
  });

  return groups;
}

Color _tableGroupAccentColor(_KitchenTableGroup group) {
  final maxWaiting = group.items
      .map(_waitingMinutes)
      .fold<int>(0, (max, value) => value > max ? value : max);
  if (maxWaiting >= 15) return AppColors.error;
  if (maxWaiting >= 5) return AppColors.warning;
  return AppColors.textMuted;
}

String _statusTitle(KitchenOrderItemStatus? status) {
  return switch (status) {
    KitchenOrderItemStatus.pending => 'Chờ chế biến',
    KitchenOrderItemStatus.preparing => 'Đang chế biến',
    KitchenOrderItemStatus.ready => 'Đã hoàn thành',
    KitchenOrderItemStatus.cancelled => 'Đã hủy',
    null => 'Tất cả món',
  };
}

Color _statusColor(KitchenOrderItemStatus status) {
  return switch (status) {
    KitchenOrderItemStatus.pending => AppColors.primary,
    KitchenOrderItemStatus.preparing => AppColors.warning,
    KitchenOrderItemStatus.ready => AppColors.success,
    KitchenOrderItemStatus.cancelled => AppColors.error,
  };
}

int _waitingMinutes(KitchenOrderItem item) {
  final orderedAt = item.orderedAt;
  if (orderedAt == null) return 0;
  return DateTime.now().difference(orderedAt.toLocal()).inMinutes.clamp(0, 999);
}

String _waitingLabel(KitchenOrderItem item) {
  final minutes = _waitingMinutes(item);
  if (minutes <= 0) return 'Vừa gọi';
  return '$minutes phút trước';
}

Future<void> _runItemAction(
  BuildContext context,
  Future<KitchenOrderItem> Function() action, {
  required String successMessage,
}) async {
  try {
    await action();
    if (context.mounted) _showSnack(context, successMessage);
  } catch (error) {
    if (context.mounted) _showSnack(context, _cleanError(error));
  }
}

Future<void> _runBulkAction(
  BuildContext context,
  Future<KitchenBulkUpdateResult?> Function() action,
) async {
  try {
    final result = await action();
    if (!context.mounted || result == null) return;
    final failed = result.failedItems.length;
    final updated = result.updatedItems.length;
    _showSnack(
      context,
      failed == 0
          ? 'Đã cập nhật $updated món'
          : 'Đã cập nhật $updated món, $failed món lỗi',
    );
  } catch (error) {
    if (context.mounted) _showSnack(context, _cleanError(error));
  }
}

Future<void> _runGroupedItemAction(
  BuildContext context,
  Future<int> Function() action, {
  required String Function(int updated) successMessage,
}) async {
  try {
    final updated = await action();
    if (!context.mounted) return;
    _showSnack(
      context,
      updated == 0 ? 'Không có món cần cập nhật' : successMessage(updated),
    );
  } catch (error) {
    if (context.mounted) _showSnack(context, _cleanError(error));
  }
}

Future<void> _runTableAction(
  BuildContext context,
  Future<int> Function() action,
) async {
  try {
    final updated = await action();
    if (!context.mounted) return;
    _showSnack(
      context,
      updated == 0
          ? 'Bàn này không còn món cần cập nhật'
          : 'Đã hoàn thành $updated món trong bàn',
    );
  } catch (error) {
    if (context.mounted) _showSnack(context, _cleanError(error));
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}
