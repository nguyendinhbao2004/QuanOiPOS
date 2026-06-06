import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../providers/store_inventory_import_products_mock_provider.dart';

class StoreInventoryImportProductsPage extends ConsumerWidget {
  final int storeId;

  const StoreInventoryImportProductsPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));

    return Scaffold(
      backgroundColor: AppColors.background,
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

class _ReadyView extends ConsumerStatefulWidget {
  final int storeId;

  const _ReadyView({required this.storeId});

  @override
  ConsumerState<_ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends ConsumerState<_ReadyView> {
  final Map<String, int> _quantitiesBySku = {};
  final Map<String, String> _pricesBySku = {};
  _InventoryImportProductsMode _mode =
      _InventoryImportProductsMode.selectProducts;

  int get _totalSelectedQuantity {
    return _quantitiesBySku.values.fold(
      0,
      (total, quantity) => total + quantity,
    );
  }

  void _addProduct(StoreInventoryImportProductMockItem product) {
    setState(() {
      _quantitiesBySku[product.sku] = 1;
    });
  }

  void _incrementProduct(StoreInventoryImportProductMockItem product) {
    setState(() {
      _quantitiesBySku[product.sku] = (_quantitiesBySku[product.sku] ?? 0) + 1;
    });
  }

  void _decrementProduct(StoreInventoryImportProductMockItem product) {
    setState(() {
      final currentQuantity = _quantitiesBySku[product.sku] ?? 0;
      if (currentQuantity <= 1) {
        _quantitiesBySku.remove(product.sku);
        return;
      }

      _quantitiesBySku[product.sku] = currentQuantity - 1;
    });
  }

  void _showCreateDraft() {
    setState(() {
      _mode = _InventoryImportProductsMode.createDraft;
    });
  }

  void _showProductSelection() {
    setState(() {
      _mode = _InventoryImportProductsMode.selectProducts;
    });
  }

  void _updateProductPrice(
    StoreInventoryImportProductMockItem product,
    String value,
  ) {
    setState(() {
      _pricesBySku[product.sku] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Gate this page with AppPermissionCodes.inventoryView or a more
    // specific import product permission when backend PBAC is available.
    final products = ref.watch(storeInventoryImportProductsMockProvider);
    final totalSelectedQuantity = _totalSelectedQuantity;
    final hasSelection = totalSelectedQuantity > 0;

    final selectedProducts = products
        .where((product) => (_quantitiesBySku[product.sku] ?? 0) > 0)
        .toList(growable: false);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: _mode == _InventoryImportProductsMode.createDraft
            ? _InventoryImportDraftView(
                selectedProducts: selectedProducts,
                quantitiesBySku: _quantitiesBySku,
                pricesBySku: _pricesBySku,
                onBack: _showProductSelection,
                onAddProduct: _showProductSelection,
                onIncrement: _incrementProduct,
                onDecrement: _decrementProduct,
                onPriceChanged: _updateProductPrice,
              )
            : SizedBox.expand(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _InventoryImportProductsHeader(storeId: widget.storeId),
                        const _InventoryImportProductFilters(),
                        Expanded(
                          child: products.isEmpty
                              ? const _EmptyProductView()
                              : ListView.separated(
                                  padding: EdgeInsets.only(
                                    bottom: hasSelection
                                        ? AppConstants.spacingXxl * 2
                                        : AppConstants.spacingXxl,
                                  ),
                                  itemBuilder: (context, index) {
                                    final product = products[index];
                                    return _InventoryImportProductTile(
                                      product: product,
                                      quantity:
                                          _quantitiesBySku[product.sku] ?? 0,
                                      onAdd: () => _addProduct(product),
                                      onIncrement: () =>
                                          _incrementProduct(product),
                                      onDecrement: () =>
                                          _decrementProduct(product),
                                    );
                                  },
                                  separatorBuilder: (context, index) =>
                                      const Divider(
                                        indent: AppConstants.spacingMd,
                                        endIndent: AppConstants.spacingMd,
                                      ),
                                  itemCount: products.length,
                                ),
                        ),
                      ],
                    ),
                    if (hasSelection)
                      _ImportProductsBottomActionBar(
                        selectedQuantity: totalSelectedQuantity,
                        onContinue: _showCreateDraft,
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

enum _InventoryImportProductsMode { selectProducts, createDraft }

class _InventoryImportDraftView extends StatelessWidget {
  final List<StoreInventoryImportProductMockItem> selectedProducts;
  final Map<String, int> quantitiesBySku;
  final Map<String, String> pricesBySku;
  final VoidCallback onBack;
  final VoidCallback onAddProduct;
  final void Function(StoreInventoryImportProductMockItem product) onIncrement;
  final void Function(StoreInventoryImportProductMockItem product) onDecrement;
  final void Function(StoreInventoryImportProductMockItem product, String value)
  onPriceChanged;

  const _InventoryImportDraftView({
    required this.selectedProducts,
    required this.quantitiesBySku,
    required this.pricesBySku,
    required this.onBack,
    required this.onAddProduct,
    required this.onIncrement,
    required this.onDecrement,
    required this.onPriceChanged,
  });

  int get _totalQuantity {
    return selectedProducts.fold(0, (total, product) {
      return total + (quantitiesBySku[product.sku] ?? 0);
    });
  }

  int get _totalAmount {
    return selectedProducts.fold(0, (total, product) {
      final quantity = quantitiesBySku[product.sku] ?? 0;
      final price = _parseMockPrice(pricesBySku[product.sku] ?? '');
      return total + (quantity * price);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InventoryImportDraftHeader(onBack: onBack),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingLg),
            children: [
              const _SupplierSelectorRow(),
              _AddProductOutlineButton(onPressed: onAddProduct),
              Material(
                color: AppColors.surface,
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < selectedProducts.length;
                      index++
                    ) ...[
                      _DraftProductTile(
                        product: selectedProducts[index],
                        quantity:
                            quantitiesBySku[selectedProducts[index].sku] ?? 0,
                        priceText:
                            pricesBySku[selectedProducts[index].sku] ?? '',
                        onIncrement: () => onIncrement(selectedProducts[index]),
                        onDecrement: () => onDecrement(selectedProducts[index]),
                        onPriceChanged: (value) =>
                            onPriceChanged(selectedProducts[index], value),
                      ),
                      if (index < selectedProducts.length - 1)
                        const Divider(
                          height: 1,
                          indent: AppConstants.spacingMd,
                          endIndent: AppConstants.spacingMd,
                        ),
                    ],
                  ],
                ),
              ),
              _DraftSummary(
                totalQuantity: _totalQuantity,
                totalAmount: _totalAmount,
              ),
              const _DraftNoteRow(),
            ],
          ),
        ),
        const _DraftBottomActions(),
      ],
    );
  }
}

int _parseMockPrice(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(digits) ?? 0;
}

class _InventoryImportDraftHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _InventoryImportDraftHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            key: const Key('inventory_import_draft_back_action'),
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              'Tạo nhập hàng',
              textAlign: TextAlign.center,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'In phiếu',
            icon: const Icon(Icons.print_outlined),
            color: AppColors.textPrimary,
            onPressed: () => _showComingSoon(context, 'In phiếu nhập'),
          ),
        ],
      ),
    );
  }
}

class _SupplierSelectorRow extends StatelessWidget {
  const _SupplierSelectorRow();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () => _showComingSoon(context, 'Chọn nhà cung cấp'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_box_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Text(
                  'Chọn nhà cung cấp',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddProductOutlineButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddProductOutlineButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        0,
        AppConstants.spacingMd,
        AppConstants.spacingSm,
      ),
      child: OutlinedButton(
        key: const Key('inventory_import_draft_add_product_action'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 42),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          textStyle: AppTextStyles.labelSm,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
        child: const Text('+ Thêm sản phẩm'),
      ),
    );
  }
}

class _DraftProductTile extends StatelessWidget {
  final StoreInventoryImportProductMockItem product;
  final int quantity;
  final String priceText;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<String> onPriceChanged;

  const _DraftProductTile({
    required this.product,
    required this.quantity,
    required this.priceText,
    required this.onIncrement,
    required this.onDecrement,
    required this.onPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final lineTotal = quantity * _parseMockPrice(priceText);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ProductThumb(),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(product.sku, style: AppTextStyles.bodyXs),
                const SizedBox(height: AppConstants.spacingSm),
                _ProductQuantityStepper(
                  sku: 'draft_${product.sku}',
                  quantity: quantity,
                  onIncrement: onIncrement,
                  onDecrement: onDecrement,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 92,
                child: TextFormField(
                  key: Key('inventory_import_product_price_${product.sku}'),
                  initialValue: priceText,
                  onChanged: onPriceChanged,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Giá',
                    hintText: '0',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingSm,
                      vertical: AppConstants.spacingXs,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                lineTotal.toString(),
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DraftSummary extends StatelessWidget {
  final int totalQuantity;
  final int totalAmount;

  const _DraftSummary({required this.totalQuantity, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppConstants.spacingSm),
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      child: Column(
        children: [
          _DraftSummaryRow(label: 'Tổng số lượng', value: '$totalQuantity'),
          _DraftSummaryRow(
            label: 'Tổng tiền hàng (Gồm VAT)',
            value: totalAmount.toString(),
          ),
          _DraftSummaryRow(
            label: 'Tổng cộng',
            value: totalAmount.toString(),
            isTotal: true,
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _DraftSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  const _DraftSummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = isTotal
        ? AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w800)
        : AppTextStyles.bodySm;
    final valueStyle = AppTextStyles.labelSm.copyWith(
      color: valueColor ?? AppColors.textPrimary,
      fontWeight: FontWeight.w800,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingXs,
      ),
      child: Row(
        children: [
          Text(label, style: labelStyle),
          const Spacer(),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

class _DraftNoteRow extends StatelessWidget {
  const _DraftNoteRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppConstants.spacingSm),
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showComingSoon(context, 'Ghi chú đơn hàng'),
              child: Text(
                'Ghi chú đơn hàng',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => _showComingSoon(context, 'Ảnh phiếu nhập'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.square(44),
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Icon(Icons.image_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}

class _DraftBottomActions extends StatelessWidget {
  const _DraftBottomActions();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: ElevatedButton(
            onPressed: () => _showComingSoon(context, 'Nhập hàng'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              textStyle: AppTextStyles.buttonSm,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Text('Nhập hàng'),
          ),
        ),
      ),
    );
  }
}

class _ImportProductsBottomActionBar extends StatelessWidget {
  final int selectedQuantity;
  final VoidCallback onContinue;

  const _ImportProductsBottomActionBar({
    required this.selectedQuantity,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppConstants.spacingMd,
      right: AppConstants.spacingMd,
      bottom: MediaQuery.paddingOf(context).bottom + AppConstants.spacingMd,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('inventory_import_products_continue_action'),
          onTap: onContinue,
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
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.surface,
                      size: 24,
                    ),
                    Positioned(
                      right: -7,
                      top: -7,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXl,
                          ),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          selectedQuantity.toString(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Text(
                    '$selectedQuantity SP',
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

class _InventoryImportProductsHeader extends StatelessWidget {
  final int storeId;

  const _InventoryImportProductsHeader({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.goNamed(
              RouteNames.storeInventoryImport,
              pathParameters: {'storeId': storeId.toString()},
            ),
          ),
          Expanded(
            child: Text(
              'Nhập hàng',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Tìm kiếm',
            icon: const Icon(Icons.search_rounded),
            color: AppColors.textPrimary,
            onPressed: () => _showComingSoon(context, 'Tìm kiếm sản phẩm'),
          ),
          IconButton(
            tooltip: 'Quét mã',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            color: AppColors.textPrimary,
            onPressed: () => _showComingSoon(context, 'Quét mã sản phẩm'),
          ),
          IconButton(
            tooltip: 'Thao tác nhanh',
            icon: const Icon(Icons.flash_on_outlined),
            color: AppColors.textPrimary,
            onPressed: () => _showComingSoon(context, 'Thao tác nhanh'),
          ),
        ],
      ),
    );
  }
}

class _InventoryImportProductFilters extends StatelessWidget {
  const _InventoryImportProductFilters();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingSm,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
      ),
      child: Wrap(
        spacing: AppConstants.spacingSm,
        runSpacing: AppConstants.spacingSm,
        children: const [
          _ImportProductFilterChip(label: 'Sản phẩm'),
          _ImportProductFilterChip(label: 'Danh mục'),
        ],
      ),
    );
  }
}

class _ImportProductFilterChip extends StatelessWidget {
  final String label;

  const _ImportProductFilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showComingSoon(context, label),
      iconAlignment: IconAlignment.end,
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm,
        ),
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.borderStrong),
        textStyle: AppTextStyles.labelXs,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
      ),
    );
  }
}

class _InventoryImportProductTile extends StatelessWidget {
  final StoreInventoryImportProductMockItem product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _InventoryImportProductTile({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
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
            const _ProductThumb(),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    '${product.sku}  |  Còn: ${product.stockQuantity}',
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
            quantity > 0
                ? _ProductQuantityStepper(
                    sku: product.sku,
                    quantity: quantity,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement,
                  )
                : _AddProductButton(sku: product.sku, onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}

class _ProductQuantityStepper extends StatelessWidget {
  final String sku;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ProductQuantityStepper({
    required this.sku,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('inventory_import_product_stepper_$sku'),
      height: 36,
      constraints: const BoxConstraints(minWidth: 104),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityIconButton(
            key: Key('inventory_import_product_decrement_$sku'),
            icon: Icons.remove_rounded,
            onPressed: onDecrement,
          ),
          SizedBox(
            width: 32,
            child: Text(
              quantity.toString(),
              key: Key('inventory_import_product_quantity_$sku'),
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _QuantityIconButton(
            key: Key('inventory_import_product_increment_$sku'),
            icon: Icons.add_rounded,
            onPressed: onIncrement,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _QuantityIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _QuantityIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: color,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.textMuted,
        size: 22,
      ),
    );
  }
}

class _AddProductButton extends StatelessWidget {
  final String sku;
  final VoidCallback onPressed;

  const _AddProductButton({required this.sku, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: ElevatedButton(
        key: Key('inventory_import_product_add_$sku'),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          padding: EdgeInsets.zero,
          minimumSize: const Size.square(36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
        child: const Icon(Icons.add_rounded, size: 20),
      ),
    );
  }
}

class _EmptyProductView extends StatelessWidget {
  const _EmptyProductView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
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
              'Chưa có sản phẩm',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXs),
            const Text(
              'Danh sách sản phẩm nhập hàng sẽ hiển thị tại đây.',
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
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

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$feature sẽ được triển khai sau')));
}
