import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../../presentation/widgets/store_bottom_sheet_panel.dart';
import '../../domain/entities/inventory_document.dart';
import '../controllers/inventory_document_notifiers.dart';
import '../controllers/inventory_document_state.dart';
import 'inventory_import_item_picker_page.dart';
import '../providers/inventory_document_providers.dart';

String _formatInventoryQuantity(double quantity) =>
    quantity == quantity.roundToDouble()
    ? quantity.toStringAsFixed(0)
    : quantity.toString();

String _draftItemStockLabel(InventorySelectableItem item) {
  final stock = _formatInventoryQuantity(item.currentQuantity);
  if (item.type == InventoryDocumentItemType.product) {
    return '${item.type.label} · Tồn $stock';
  }
  return item.unit.isEmpty
      ? '${item.type.label} · Tồn $stock'
      : '${item.type.label} · Tồn $stock ${item.unit}';
}

class InventoryDocumentEditorPage extends ConsumerWidget {
  final int storeId;
  final InventoryDocumentType documentType;
  final int? documentId;
  const InventoryDocumentEditorPage({
    super.key,
    required this.storeId,
    this.documentType = InventoryDocumentType.import,
    this.documentId,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(storeAccessNotifierProvider(storeId));
    if (access.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (access.status != StoreAccessStatus.ready ||
        !access.can(AppPermissionCodes.inventoryView)) {
      return Scaffold(
        body: Center(
          child: Text(
            access.errorMessage ?? 'Bạn chưa có quyền truy cập phiếu kho.',
          ),
        ),
      );
    }
    return _DraftView(
      storeId: storeId,
      documentType: documentType,
      documentId: documentId,
      canEdit: documentType == InventoryDocumentType.manualIssue
          ? true
          : access.can(AppPermissionCodes.inventoryImport),
    );
  }
}

class _DraftView extends ConsumerWidget {
  final int storeId;
  final InventoryDocumentType documentType;
  final int? documentId;
  final bool canEdit;
  const _DraftView({
    required this.storeId,
    required this.documentType,
    required this.documentId,
    required this.canEdit,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = InventoryDocumentEditorArgs(
      storeId: storeId,
      type: documentType,
      documentId: documentId,
    );
    final state = ref.watch(inventoryDocumentEditorNotifierProvider(args));
    final notifier = ref.read(
      inventoryDocumentEditorNotifierProvider(args).notifier,
    );
    if (state.status == InventoryDocumentLoadStatus.initial ||
        state.status == InventoryDocumentLoadStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.status == InventoryDocumentLoadStatus.error) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: notifier.load,
            child: Text(state.errorMessage ?? 'Thử lại'),
          ),
        ),
      );
    }
    final editable = canEdit && state.isDraft;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                _DraftHeader(
                  title: documentId == null
                      ? documentType == InventoryDocumentType.import
                            ? 'Tạo phiếu nhập hàng'
                            : 'Tạo phiếu xuất hàng'
                      : state.document!.documentCode,
                  onBack: () => context.goNamed(
                    documentType == InventoryDocumentType.import
                        ? RouteNames.storeInventoryImport
                        : RouteNames.storeInventoryExport,
                    pathParameters: {'storeId': '$storeId'},
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(
                      bottom: AppConstants.spacingLg,
                    ),
                    children: [
                      if (state.errorMessage != null)
                        _Alert(
                          message: state.errorMessage!,
                          error: state.shortages.isNotEmpty,
                        ),
                      if (documentType == InventoryDocumentType.import)
                        _VendorRow(
                          state: state,
                          enabled: editable,
                          onPick: () =>
                              _showVendorSheet(context, state, notifier),
                          onCreate: () =>
                              _showCreateVendorSheet(context, notifier),
                        )
                      else
                        _IssueInfoRow(
                          state: state,
                          enabled: editable,
                          onReasonChanged: notifier.setReason,
                          onDestinationChanged: notifier.setDestinationName,
                        ),
                      _AddItemButton(
                        enabled: editable,
                        onPressed: () async {
                          final selected = await context
                              .pushNamed<List<InventorySelectableItem>>(
                                RouteNames.storeInventoryImportItemPicker,
                                pathParameters: {'storeId': '$storeId'},
                                extra: InventoryItemPickerArgs(
                                  documentType: documentType,
                                  selectedItems: state.items,
                                ),
                              );
                          if (selected != null) {
                            for (final item in selected) {
                              notifier.addItem(item);
                            }
                          }
                        },
                      ),
                      if (state.items.isEmpty)
                        const _EmptyItems()
                      else
                        Material(
                          color: AppColors.surface,
                          child: Column(
                            children: state.items
                                .map(
                                  (item) => _ItemTile(
                                    item: item,
                                    shortage: state
                                        .shortages['${item.item.type.apiValue}:${item.item.id}'],
                                    editable: editable,
                                    documentType: documentType,
                                    onRemove: () => notifier.removeItem(item),
                                    onQuantity: (value) => notifier.updateItem(
                                      item,
                                      quantity: value,
                                    ),
                                    onCost: (value) => notifier.updateItem(
                                      item,
                                      unitCost: value,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      _Summary(state: state, documentType: documentType),
                      _NoteRow(
                        note: state.note,
                        documentType: documentType,
                        enabled: editable,
                        onChanged: notifier.setNote,
                      ),
                    ],
                  ),
                ),
                if (editable)
                  _BottomActions(
                    isSaving: state.isSaving,
                    isCompleting: state.isCompleting,
                    isCancelling: state.isCancelling,
                    canComplete: state.document != null,
                    canCancel: state.document != null,
                    onSave: () async {
                      final document = await notifier.save();
                      if (document != null && context.mounted) {
                        context.goNamed(
                          documentType == InventoryDocumentType.import
                              ? RouteNames.storeInventoryImportDetail
                              : RouteNames.storeInventoryExportDetail,
                          pathParameters: {
                            'storeId': '$storeId',
                            'documentId': '${document.id}',
                          },
                        );
                      }
                    },
                    onComplete: notifier.complete,
                    onCancel: notifier.cancel,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DraftHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _DraftHeader({required this.title, required this.onBack});
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(
      AppConstants.spacingXs,
      AppConstants.spacingSm,
      AppConstants.spacingXs,
      AppConstants.spacingXs,
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 48),
      ],
    ),
  );
}

class _VendorRow extends StatelessWidget {
  final InventoryDocumentEditorState state;
  final bool enabled;
  final VoidCallback onPick, onCreate;
  const _VendorRow({
    required this.state,
    required this.enabled,
    required this.onPick,
    required this.onCreate,
  });
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
    padding: const EdgeInsets.symmetric(
      horizontal: AppConstants.spacingMd,
      vertical: AppConstants.spacingSm,
    ),
    child: Row(
      children: [
        const Icon(Icons.storefront_outlined, color: AppColors.primary),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: InkWell(
            onTap: enabled ? onPick : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhà cung cấp',
                  style: AppTextStyles.bodyXs.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  state.vendors
                          .where((v) => v.id == state.vendorId)
                          .map((v) => v.name)
                          .firstOrNull ??
                      'Chọn nhà cung cấp',
                  style: AppTextStyles.labelSm,
                ),
              ],
            ),
          ),
        ),
        if (enabled)
          TextButton(onPressed: onCreate, child: const Text('Tạo nhanh')),
        if (enabled)
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ],
    ),
  );
}

class _IssueInfoRow extends StatelessWidget {
  final InventoryDocumentEditorState state;
  final bool enabled;
  final ValueChanged<InventoryIssueReason?> onReasonChanged;
  final ValueChanged<String> onDestinationChanged;

  const _IssueInfoRow({
    required this.state,
    required this.enabled,
    required this.onReasonChanged,
    required this.onDestinationChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
    padding: const EdgeInsets.all(AppConstants.spacingMd),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<InventoryIssueReason>(
          initialValue: state.reason,
          decoration: const InputDecoration(labelText: 'Lý do xuất kho'),
          items: InventoryIssueReason.values
              .map(
                (reason) =>
                    DropdownMenuItem(value: reason, child: Text(reason.label)),
              )
              .toList(),
          onChanged: enabled ? onReasonChanged : null,
        ),
        if (state.reason == InventoryIssueReason.transferOut) ...[
          const SizedBox(height: AppConstants.spacingSm),
          TextFormField(
            initialValue: state.destinationName,
            enabled: enabled,
            decoration: const InputDecoration(labelText: 'Nơi nhận'),
            onChanged: onDestinationChanged,
          ),
        ],
      ],
    ),
  );
}

class _AddItemButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _AddItemButton({required this.enabled, required this.onPressed});
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.background,
    padding: const EdgeInsets.fromLTRB(
      AppConstants.spacingMd,
      AppConstants.spacingMd,
      AppConstants.spacingMd,
      AppConstants.spacingSm,
    ),
    child: OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Thêm hàng hóa'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        textStyle: AppTextStyles.labelSm,
      ),
    ),
  );
}

class _ItemTile extends StatelessWidget {
  final InventoryDocumentDraftItem item;
  final InventoryShortageItem? shortage;
  final bool editable;
  final InventoryDocumentType documentType;
  final VoidCallback onRemove;
  final ValueChanged<double> onQuantity, onCost;
  const _ItemTile({
    required this.item,
    required this.shortage,
    required this.editable,
    required this.documentType,
    required this.onRemove,
    required this.onQuantity,
    required this.onCost,
  });
  @override
  Widget build(BuildContext context) => Container(
    color: shortage == null
        ? AppColors.surface
        : AppColors.error.withValues(alpha: .08),
    padding: const EdgeInsets.all(AppConstants.spacingMd),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: Icon(
                item.item.type == InventoryDocumentItemType.product
                    ? Icons.inventory_2_outlined
                    : Icons.kitchen_outlined,
                color: AppColors.textMuted,
              ),
            ),
            if (editable)
              Positioned(
                left: -8,
                top: -8,
                child: InkWell(
                  onTap: onRemove,
                  child: const CircleAvatar(
                    radius: 9,
                    backgroundColor: AppColors.textMuted,
                    child: Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.item.name,
                style: AppTextStyles.labelSm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _draftItemStockLabel(item.item),
                style: AppTextStyles.bodyXs,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Row(
                children: [
                  Expanded(
                    child: item.item.type == InventoryDocumentItemType.product
                        ? _ProductQuantityStepper(
                            value: item.quantity,
                            enabled: editable,
                            onChanged: onQuantity,
                          )
                        : _Number(
                            label: item.item.unit.isEmpty
                                ? 'SL'
                                : 'SL (${item.item.unit})',
                            value: item.quantity,
                            enabled: editable,
                            allowDecimal: true,
                            onChanged: onQuantity,
                          ),
                  ),
                  if (documentType == InventoryDocumentType.import) ...[
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: _Number(
                        label: 'Đơn giá',
                        value: item.unitCost,
                        enabled: editable,
                        allowDecimal: true,
                        onChanged: onCost,
                      ),
                    ),
                  ],
                ],
              ),
              if (shortage case final shortage?)
                Padding(
                  padding: const EdgeInsets.only(top: AppConstants.spacingXs),
                  child: Text(
                    'Thiếu ${shortage.shortageQuantity} ${shortage.unit}',
                    style: AppTextStyles.bodyXs.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (documentType == InventoryDocumentType.import) ...[
          const SizedBox(width: AppConstants.spacingSm),
          Text(
            item.lineTotal.toStringAsFixed(0),
            style: AppTextStyles.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    ),
  );
}

class _Number extends StatelessWidget {
  final String label;
  final double value;
  final bool enabled;
  final bool allowDecimal;
  final ValueChanged<double> onChanged;
  const _Number({
    required this.label,
    required this.value,
    required this.enabled,
    required this.allowDecimal,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.bodyXs),
      const SizedBox(height: AppConstants.spacingXs),
      SizedBox(
        height: 36,
        child: TextFormField(
          initialValue: _formatInventoryQuantity(value),
          enabled: enabled,
          keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
          inputFormatters: allowDecimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}'))]
              : [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingSm,
              vertical: AppConstants.spacingSm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppColors.borderStrong),
            ),
          ),
          onChanged: (text) => onChanged(double.tryParse(text) ?? 0),
        ),
      ),
    ],
  );
}

class _ProductQuantityStepper extends StatelessWidget {
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _ProductQuantityStepper({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final quantity = value.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SL', style: AppTextStyles.bodyXs),
        const SizedBox(height: AppConstants.spacingXs),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Row(
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
                enabled: enabled && quantity > 1,
                onPressed: () => onChanged((quantity - 1).toDouble()),
              ),
              Expanded(
                child: Text(
                  quantity.toString(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StepperButton(
                icon: Icons.add_rounded,
                color: AppColors.primary,
                enabled: enabled,
                onPressed: () => onChanged((quantity + 1).toDouble()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 34,
    height: 36,
    child: IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      color: color,
      padding: EdgeInsets.zero,
    ),
  );
}

class _Summary extends StatelessWidget {
  final InventoryDocumentEditorState state;
  final InventoryDocumentType documentType;
  const _Summary({required this.state, required this.documentType});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: AppConstants.spacingSm),
    color: AppColors.surface,
    padding: const EdgeInsets.all(AppConstants.spacingMd),
    child: Column(
      children: [
        _row(
          'Tổng số lượng',
          state.items
              .fold<double>(0, (sum, item) => sum + item.quantity)
              .toStringAsFixed(0),
        ),
        _row('Mặt hàng', '${state.items.length}'),
        if (documentType == InventoryDocumentType.import) ...[
          const Divider(),
          _row('Tổng cộng', state.totalAmount.toStringAsFixed(0), total: true),
        ],
      ],
    ),
  );
  Widget _row(String label, String value, {bool total = false}) => Row(
    children: [
      Text(
        label,
        style: (total ? AppTextStyles.label : AppTextStyles.bodySm).copyWith(
          color: total ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: total ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      const Spacer(),
      Text(
        value,
        style: (total ? AppTextStyles.h4 : AppTextStyles.labelSm).copyWith(
          color: total ? AppColors.primary : AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _NoteRow extends StatelessWidget {
  final String note;
  final InventoryDocumentType documentType;
  final bool enabled;
  final ValueChanged<String> onChanged;
  const _NoteRow({
    required this.note,
    required this.documentType,
    required this.enabled,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: AppConstants.spacingSm),
    color: AppColors.surface,
    padding: const EdgeInsets.all(AppConstants.spacingMd),
    child: TextFormField(
      initialValue: note,
      enabled: enabled,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: documentType == InventoryDocumentType.import
            ? 'Ghi chú phiếu nhập'
            : 'Ghi chú phiếu xuất',
        border: InputBorder.none,
      ),
      onChanged: onChanged,
    ),
  );
}

class _BottomActions extends StatelessWidget {
  final bool isSaving, isCompleting, isCancelling, canComplete, canCancel;
  final VoidCallback onSave, onComplete, onCancel;
  const _BottomActions({
    required this.isSaving,
    required this.isCompleting,
    required this.isCancelling,
    required this.canComplete,
    required this.canCancel,
    required this.onSave,
    required this.onComplete,
    required this.onCancel,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          children: [
            if (!canComplete)
              Expanded(
                child: ElevatedButton(
                  onPressed: isSaving ? null : onSave,
                  child: Text(isSaving ? 'Đang lưu...' : 'Lưu nháp'),
                ),
              )
            else ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isSaving ? null : onSave,
                  child: const Text('Cập nhật'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              if (canCancel) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: isCancelling ? null : onCancel,
                    child: Text(isCancelling ? 'Đang hủy...' : 'Hủy phiếu'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: isCompleting ? null : onComplete,
                  child: Text(
                    isCompleting ? 'Đang hoàn thành...' : 'Hoàn thành',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Alert extends StatelessWidget {
  final String message;
  final bool error;
  const _Alert({required this.message, required this.error});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(AppConstants.spacingMd),
    padding: const EdgeInsets.all(AppConstants.spacingSm),
    color: error ? AppColors.error.withValues(alpha: .1) : AppColors.surface,
    child: Text(message, style: AppTextStyles.bodySm),
  );
}

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.all(AppConstants.spacingLg),
    child: Text(
      'Chưa có hàng hóa trong phiếu nhập',
      textAlign: TextAlign.center,
      style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
    ),
  );
}

Future<void> _showVendorSheet(
  BuildContext context,
  InventoryDocumentEditorState state,
  InventoryDocumentEditorNotifier notifier,
) async {
  var query = '';
  final id = await showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SizedBox(
      height: MediaQuery.sizeOf(context).height * .65,
      child: StoreBottomSheetPanel(
        title: 'Chọn nhà cung cấp',
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final vendors = state.vendors
                .where(
                  (vendor) =>
                      vendor.name.toLowerCase().contains(query.toLowerCase()) ||
                      (vendor.phone ?? '').contains(query),
                )
                .toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Tìm nhà cung cấp',
                    ),
                    onChanged: (value) => setSheetState(() => query = value),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        title: const Text('Không chọn'),
                        onTap: () => Navigator.pop(context),
                      ),
                      ...vendors.map(
                        (vendor) => ListTile(
                          title: Text(vendor.name),
                          subtitle: Text(vendor.phone ?? ''),
                          trailing: state.vendorId == vendor.id
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, vendor.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
  if (context.mounted) notifier.setVendor(id);
}

Future<void> _showCreateVendorSheet(
  BuildContext context,
  InventoryDocumentEditorNotifier notifier,
) async {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.sizeOf(sheetContext).height * .62,
      child: StoreBottomSheetPanel(
        title: 'Tạo nhanh nhà cung cấp',
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppConstants.spacingMd,
            AppConstants.spacingMd,
            AppConstants.spacingMd,
            MediaQuery.viewInsetsOf(sheetContext).bottom +
                AppConstants.spacingMd,
          ),
          child: Column(
            children: [
              Text('Tạo nhanh nhà cung cấp', style: AppTextStyles.h4),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Tên nhà cung cấp',
                ),
              ),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final vendor = await notifier.createVendor(
                      name: name.text,
                      phone: phone.text,
                      address: address.text,
                    );
                    if (vendor != null && sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                  child: const Text('Tạo và chọn'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  name.dispose();
  phone.dispose();
  address.dispose();
}
