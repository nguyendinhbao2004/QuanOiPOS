import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../../product_management/domain/entities/product.dart';
import '../../../product_management/domain/entities/product_topping.dart';
import '../../../product_management/domain/entities/product_variant_draft.dart';
import '../controllers/order_notifiers.dart';
import '../controllers/order_states.dart';
import '../providers/order_management_providers.dart';

class OrderCreatePage extends ConsumerWidget {
  final int storeId;
  final int tableSessionId;

  const OrderCreatePage({
    super.key,
    required this.storeId,
    required this.tableSessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));
    if (accessState.status != StoreAccessStatus.ready) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tạo đơn hàng')),
        body: Center(
          child:
              accessState.status == StoreAccessStatus.initial ||
                  accessState.status == StoreAccessStatus.loading
              ? const CircularProgressIndicator()
              : Text(accessState.errorMessage ?? 'Không thể truy cập cửa hàng'),
        ),
      );
    }

    final access = OrderSessionAccess(
      storeId: storeId,
      tableSessionId: tableSessionId,
      isSessionOpen: true,
      canViewOrder: accessState.can(AppPermissionCodes.orderView),
      canCreateOrder: accessState.can(AppPermissionCodes.orderCreate),
    );
    final state = ref.watch(orderCreateNotifierProvider(access));
    final notifier = ref.read(orderCreateNotifierProvider(access).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tạo đơn hàng')),
      bottomNavigationBar: state.status == OrderLoadStatus.ready
          ? _CartBar(
              state: state,
              onOpenCart: () => _showCart(context, access),
              onSubmit: state.cart.isEmpty || state.isSubmitting
                  ? null
                  : () => _submit(context, notifier),
            )
          : null,
      body: switch (state.status) {
        OrderLoadStatus.initial || OrderLoadStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        OrderLoadStatus.forbidden => _CreateMessage(
          icon: Icons.lock_outline_rounded,
          message: state.errorMessage ?? 'Bạn chưa có quyền tạo đơn hàng.',
        ),
        OrderLoadStatus.error => _CreateMessage(
          icon: Icons.error_outline_rounded,
          message: state.errorMessage ?? 'Không thể tải menu.',
          onRetry: notifier.load,
        ),
        OrderLoadStatus.ready => _MenuContent(
          state: state,
          onQueryChanged: notifier.setQuery,
          onCategorySelected: notifier.selectCategory,
          onProductTap: (product) async {
            final configured = await _showConfigureItem(context, product);
            if (configured != null) notifier.addConfiguredItem(configured);
          },
        ),
      },
    );
  }

  Future<void> _submit(
    BuildContext context,
    OrderCreateNotifier notifier,
  ) async {
    try {
      await notifier.submit();
      if (context.mounted) context.pop(true);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}

class _MenuContent extends StatelessWidget {
  final OrderCreateState state;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<int?> onCategorySelected;
  final ValueChanged<Product> onProductTap;

  const _MenuContent({
    required this.state,
    required this.onQueryChanged,
    required this.onCategorySelected,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
            ? 3
            : 2;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingMd,
                  AppConstants.spacingMd,
                  AppConstants.spacingMd,
                  AppConstants.spacingSm,
                ),
                child: TextField(
                  key: const Key('order_product_search'),
                  onChanged: onQueryChanged,
                  decoration: const InputDecoration(
                    hintText: 'Tìm món',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                  ),
                  scrollDirection: Axis.horizontal,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: state.selectedCategoryId == null,
                      onSelected: (_) => onCategorySelected(null),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    for (final category in state.categories) ...[
                      ChoiceChip(
                        label: Text(category.name),
                        selected: state.selectedCategoryId == category.id,
                        onSelected: (_) => onCategorySelected(category.id),
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                    ],
                  ],
                ),
              ),
            ),
            if (state.visibleProducts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _CreateMessage(
                  icon: Icons.restaurant_menu_rounded,
                  message: 'Không tìm thấy món phù hợp.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingMd,
                  AppConstants.spacingMd,
                  AppConstants.spacingMd,
                  120,
                ),
                sliver: SliverGrid.builder(
                  itemCount: state.visibleProducts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppConstants.spacingSm,
                    crossAxisSpacing: AppConstants.spacingSm,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final product = state.visibleProducts[index];
                    return _ProductCard(
                      product: product,
                      onTap: () => onProductTap(product),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        key: Key('order_product_${product.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: product.imageUrl.isEmpty
                      ? const ColoredBox(
                          color: AppColors.muted,
                          child: Center(
                            child: Icon(Icons.restaurant_menu_rounded),
                          ),
                        )
                      : Image.network(
                          product.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: AppColors.muted,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(_currency(product.price), style: AppTextStyles.bodySm),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  final OrderCreateState state;
  final VoidCallback onOpenCart;
  final VoidCallback? onSubmit;

  const _CartBar({
    required this.state,
    required this.onOpenCart,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('open_order_cart'),
                onPressed: onOpenCart,
                icon: Badge(
                  label: Text('${state.cartQuantity}'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                label: Text(_currency(state.cartTotal)),
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: ElevatedButton(
                key: const Key('submit_order_button'),
                onPressed: onSubmit,
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tạo đơn'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<OrderCartItem?> _showConfigureItem(
  BuildContext context,
  Product product, {
  OrderCartItem? existing,
}) {
  return showModalBottomSheet<OrderCartItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ConfigureItemSheet(product: product, existing: existing),
  );
}

class _ConfigureItemSheet extends StatefulWidget {
  final Product product;
  final OrderCartItem? existing;

  const _ConfigureItemSheet({required this.product, this.existing});

  @override
  State<_ConfigureItemSheet> createState() => _ConfigureItemSheetState();
}

class _ConfigureItemSheetState extends State<_ConfigureItemSheet> {
  late ProductVariantDraft? _variant;
  late Map<int, int> _toppingQuantities;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _variant =
        widget.existing?.variant ?? _defaultVariant(widget.product.variants);
    _toppingQuantities = {
      for (final selected in widget.existing?.toppings ?? const [])
        selected.topping.id: selected.quantity,
    };
    _noteController = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        MediaQuery.viewInsetsOf(context).bottom + AppConstants.spacingMd,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.product.name, style: AppTextStyles.h3),
            if (widget.product.variants.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingLg),
              Text('Chọn phiên bản', style: AppTextStyles.h4),
              const SizedBox(height: AppConstants.spacingSm),
              Wrap(
                spacing: AppConstants.spacingSm,
                runSpacing: AppConstants.spacingSm,
                children: [
                  for (final variant in widget.product.variants)
                    ChoiceChip(
                      label: Text(
                        '${variant.name} • ${_currency(variant.price)}',
                      ),
                      selected: identical(_variant, variant),
                      onSelected: (_) => setState(() => _variant = variant),
                    ),
                ],
              ),
            ],
            if (widget.product.toppings.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingMd),
              Text('Topping', style: AppTextStyles.h4),
              for (final topping in widget.product.toppings)
                _ToppingSelector(
                  topping: topping,
                  quantity: _toppingQuantities[topping.id] ?? 0,
                  onChanged: (quantity) => setState(() {
                    if (quantity == 0) {
                      _toppingQuantities.remove(topping.id);
                    } else {
                      _toppingQuantities[topping.id] = quantity;
                    }
                  }),
                ),
            ],
            const SizedBox(height: AppConstants.spacingMd),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Ít đá, không cay...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('confirm_order_item'),
                onPressed: () {
                  if (widget.product.variants.isNotEmpty &&
                      _variant?.id == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Variant chưa có ID từ backend.'),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop(
                    OrderCartItem(
                      key: widget.existing?.key ?? '',
                      product: widget.product,
                      variant: _variant,
                      toppings: [
                        for (final topping in widget.product.toppings)
                          if ((_toppingQuantities[topping.id] ?? 0) > 0)
                            OrderCartTopping(
                              topping: topping,
                              quantity: _toppingQuantities[topping.id]!,
                            ),
                      ],
                      note: _noteController.text,
                      quantity: widget.existing?.quantity ?? 1,
                    ),
                  );
                },
                child: Text(widget.existing == null ? 'Thêm vào giỏ' : 'Lưu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToppingSelector extends StatelessWidget {
  final ProductTopping topping;
  final int quantity;
  final ValueChanged<int> onChanged;

  const _ToppingSelector({
    required this.topping,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(topping.name),
      subtitle: Text(_currency(topping.price)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity == 0 ? null : () => onChanged(quantity - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$quantity'),
          IconButton(
            onPressed: () => onChanged(quantity + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCart(BuildContext context, OrderSessionAccess access) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(orderCreateNotifierProvider(access));
        final notifier = ref.read(orderCreateNotifierProvider(access).notifier);
        return _CartSheet(
          state: state,
          onChangeQuantity: notifier.changeQuantity,
          onRemove: notifier.removeItem,
          onEdit: (item) async {
            final updated = await _showConfigureItem(
              sheetContext,
              item.product,
              existing: item,
            );
            if (updated != null) notifier.updateItem(updated);
          },
        );
      },
    ),
  );
}

class _CartSheet extends StatelessWidget {
  final OrderCreateState state;
  final void Function(String key, int delta) onChangeQuantity;
  final ValueChanged<String> onRemove;
  final ValueChanged<OrderCartItem> onEdit;

  const _CartSheet({
    required this.state,
    required this.onChangeQuantity,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        children: [
          Text('Giỏ hàng', style: AppTextStyles.h3),
          const SizedBox(height: AppConstants.spacingMd),
          Expanded(
            child: state.cart.isEmpty
                ? const Center(child: Text('Chưa có món nào trong giỏ.'))
                : ListView.separated(
                    itemCount: state.cart.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = state.cart[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => onEdit(item),
                        title: Text(item.product.name),
                        subtitle: Text(
                          '${item.variant?.name ?? ''}${item.note.isEmpty ? '' : '\n${item.note}'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => onChangeQuantity(item.key, -1),
                              icon: const Icon(Icons.remove_rounded),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              onPressed: () => onChangeQuantity(item.key, 1),
                              icon: const Icon(Icons.add_rounded),
                            ),
                            IconButton(
                              onPressed: () => onRemove(item.key),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          Row(
            children: [
              Text('Tổng cộng', style: AppTextStyles.h4),
              const Spacer(),
              Text(_currency(state.cartTotal), style: AppTextStyles.h4),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const _CreateMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textMuted),
            const SizedBox(height: AppConstants.spacingMd),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppConstants.spacingMd),
              ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}

ProductVariantDraft? _defaultVariant(List<ProductVariantDraft> variants) {
  if (variants.isEmpty) return null;
  for (final variant in variants) {
    if (variant.isDefault) return variant;
  }
  return variants.first;
}

String _currency(int value) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);
