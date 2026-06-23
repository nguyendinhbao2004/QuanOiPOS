import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_permission_codes.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../inventory_documents/domain/entities/inventory_document.dart';
import '../../inventory_documents/presentation/controllers/inventory_document_state.dart';
import '../../inventory_documents/presentation/providers/inventory_document_providers.dart';

class StoreInventoryImportPage extends ConsumerWidget {
  final int storeId;
  const StoreInventoryImportPage({super.key, required this.storeId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(storeAccessNotifierProvider(storeId));
    if (access.isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!access.can(AppPermissionCodes.inventoryView))
      return const Scaffold(
        body: Center(child: Text('Bạn chưa có quyền xem sổ nhập hàng.')),
      );
    final state = ref.watch(inventoryDocumentListNotifierProvider(storeId));
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: access.can(AppPermissionCodes.inventoryImport)
          ? FloatingActionButton(
              onPressed: () => context.goNamed(
                RouteNames.storeInventoryImportCreate,
                pathParameters: {'storeId': '$storeId'},
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                _Header(storeId),
                _Tabs(storeId, state.selectedStatus),
                _Filters(storeId),
                Expanded(child: _Ledger(storeId, state)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int storeId;
  const _Header(this.storeId);
  @override
  Widget build(BuildContext context) => Container(
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
          onPressed: () => context.goNamed(
            RouteNames.storeInventoryManagement,
            pathParameters: {'storeId': '$storeId'},
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        Expanded(
          child: Text(
            'Sổ nhập hàng',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const Icon(Icons.search_rounded, color: AppColors.textSecondary),
        const SizedBox(width: AppConstants.spacingMd),
        const Icon(
          Icons.file_download_outlined,
          color: AppColors.textSecondary,
        ),
      ],
    ),
  );
}

class _Tabs extends ConsumerWidget {
  final int storeId;
  final InventoryDocumentStatus? selected;
  const _Tabs(this.storeId, this.selected);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = <InventoryDocumentStatus?>[
      null,
      ...InventoryDocumentStatus.values,
    ];
    return Container(
      color: AppColors.surface,
      child: Row(
        children: options
            .map(
              (status) => Expanded(
                child: _Tab(
                  label: status?.label ?? 'Tất cả',
                  selected: status == selected,
                  onTap: () => ref
                      .read(
                        inventoryDocumentListNotifierProvider(storeId).notifier,
                      )
                      .setStatus(status),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSm.copyWith(
          color: selected ? AppColors.primary : AppColors.textMuted,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );
}

class _Filters extends ConsumerWidget {
  final int storeId;
  const _Filters(this.storeId);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryDocumentListNotifierProvider(storeId));
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
            child: _Filter(label, () => _showDateFilter(context, ref, storeId)),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          SizedBox(width: 124, child: _Filter('Phân loại', _noop)),
        ],
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _Filter(this.label, this.onPressed);
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
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

class _Ledger extends StatelessWidget {
  final int storeId;
  final InventoryDocumentListState state;
  const _Ledger(this.storeId, this.state);
  @override
  Widget build(BuildContext context) {
    if (state.status == InventoryDocumentLoadStatus.loading)
      return const Center(child: CircularProgressIndicator());
    if (state.page?.items.isEmpty ?? true)
      return const Center(child: Text('Chưa có phiếu nhập hàng.'));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        0,
        AppConstants.spacingMd,
        AppConstants.spacingXxl,
      ),
      itemCount: state.page!.items.length,
      separatorBuilder: (_, i) =>
          const SizedBox(height: AppConstants.spacingSm),
      itemBuilder: (context, index) =>
          _DocumentCard(storeId, state.page!.items[index]),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final int storeId;
  final InventoryDocumentSummary item;
  const _DocumentCard(this.storeId, this.item);
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
    child: InkWell(
      onTap: () => context.goNamed(
        RouteNames.storeInventoryImportDetail,
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
            _top(),
            const SizedBox(height: AppConstants.spacingSm),
            const Divider(height: 1),
            const SizedBox(height: AppConstants.spacingSm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.vendor?.name ?? 'Không có nhà cung cấp',
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
  Widget _top() => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.documentCode,
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              item.createdAt?.toLocal().toString().substring(0, 16) ?? '—',
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
  );
}

void _noop() {}

Future<void> _showDateFilter(
  BuildContext context,
  WidgetRef ref,
  int storeId,
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
      .read(inventoryDocumentListNotifierProvider(storeId).notifier)
      .setDateRange(from, to);
}
