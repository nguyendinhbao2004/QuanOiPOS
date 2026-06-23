import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import '../../domain/entities/inventory_document.dart';
import '../controllers/inventory_document_notifiers.dart';
import '../controllers/inventory_document_state.dart';
import '../providers/inventory_document_providers.dart';

String inventorySelectableItemStockLabel(InventorySelectableItem item) {
  final quantity = item.currentQuantity == item.currentQuantity.roundToDouble()
      ? item.currentQuantity.toStringAsFixed(0)
      : item.currentQuantity.toString();
  if (item.type == InventoryDocumentItemType.product) {
    return 'Còn: $quantity';
  }
  return item.unit.isEmpty ? 'Còn: $quantity' : 'Còn: $quantity ${item.unit}';
}

class InventoryImportItemPickerPage extends ConsumerStatefulWidget {
  final int storeId;
  final List selectedItems;
  const InventoryImportItemPickerPage({
    super.key,
    required this.storeId,
    required this.selectedItems,
  });
  @override
  ConsumerState<InventoryImportItemPickerPage> createState() =>
      _InventoryImportItemPickerPageState();
}

class _InventoryImportItemPickerPageState
    extends ConsumerState<InventoryImportItemPickerPage> {
  final Set<String> _selected = {};
  InventoryDocumentItemType _type = InventoryDocumentItemType.product;
  @override
  void initState() {
    super.initState();
    for (final item
        in widget.selectedItems.whereType<InventoryDocumentDraftItem>()) {
      _selected.add('${item.item.type.apiValue}:${item.item.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = InventoryDocumentEditorArgs(storeId: widget.storeId);
    final state = ref.watch(inventoryDocumentEditorNotifierProvider(args));
    final items = state.availableItems
        .where((item) => item.type == _type)
        .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Stack(
              children: [
                Column(
                  children: [
                    _header(),
                    _typeTabs(),
                    Expanded(
                      child: state.status == InventoryDocumentLoadStatus.ready
                          ? ListView.separated(
                              padding: const EdgeInsets.only(bottom: 96),
                              itemCount: items.length,
                              separatorBuilder: (_, i) => const Divider(
                                indent: AppConstants.spacingMd,
                                endIndent: AppConstants.spacingMd,
                              ),
                              itemBuilder: (_, index) => _tile(items[index]),
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ),
                if (_selected.isNotEmpty) _bottom(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
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
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        Expanded(
          child: Text(
            'Nhập hàng',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const Icon(Icons.search_rounded),
        const SizedBox(width: AppConstants.spacingMd),
        const Icon(Icons.qr_code_scanner_rounded),
      ],
    ),
  );
  Widget _typeTabs() => Container(
    color: AppColors.surface,
    child: Row(
      children: InventoryDocumentItemType.values
          .map(
            (type) => Expanded(
              child: InkWell(
                onTap: () => setState(() => _type = type),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _type == type
                            ? AppColors.primary
                            : AppColors.border,
                        width: _type == type ? 2.5 : 1,
                      ),
                    ),
                  ),
                  child: Text(
                    type.label,
                    style: AppTextStyles.labelSm.copyWith(
                      color: _type == type
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontWeight: _type == type
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
  Widget _tile(InventorySelectableItem item) {
    final key = '${item.type.apiValue}:${item.id}';
    final selected = _selected.contains(key);
    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingMd,
          AppConstants.spacingSm,
          AppConstants.spacingMd,
          AppConstants.spacingSm,
        ),
        child: Row(
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
                item.type == InventoryDocumentItemType.product
                    ? Icons.inventory_2_outlined
                    : Icons.kitchen_outlined,
                color: AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    inventorySelectableItemStockLabel(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyXs.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            SizedBox(
              width: 36,
              height: 36,
              child: ElevatedButton(
                onPressed: () => setState(
                  () => selected ? _selected.remove(key) : _selected.add(key),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected
                      ? AppColors.inputBackground
                      : AppColors.primary,
                  foregroundColor: selected
                      ? AppColors.textSecondary
                      : AppColors.surface,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size.square(36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.add_rounded,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottom() {
    final all = ref
        .read(
          inventoryDocumentEditorNotifierProvider(
            InventoryDocumentEditorArgs(storeId: widget.storeId),
          ),
        )
        .availableItems;
    final result = all
        .where((item) => _selected.contains('${item.type.apiValue}:${item.id}'))
        .toList();
    return Positioned(
      left: AppConstants.spacingMd,
      right: AppConstants.spacingMd,
      bottom: AppConstants.spacingMd,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.pop(result),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: AppConstants.spacingSm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.surface,
                  size: 24,
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Text(
                    '${_selected.length} hàng hóa',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Tiếp tục',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingXs),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.surface,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
