import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../config/router_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/entities/inventory_deduction_mode.dart';
import '../controllers/product_create_state.dart';
import '../controllers/product_management_notifier.dart';
import '../controllers/product_management_state.dart';
import '../providers/product_management_providers.dart';

class ProductManagementPage extends ConsumerWidget {
  final int storeId;

  const ProductManagementPage({super.key, required this.storeId});

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
          StoreAccessStatus.ready => _AccessReadyView(
            storeId: storeId,
            accessState: accessState,
          ),
        },
      ),
    );
  }
}

class _AccessReadyView extends ConsumerWidget {
  final int storeId;
  final StoreAccessState accessState;

  const _AccessReadyView({required this.storeId, required this.accessState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!accessState.can(AppPermissionCodes.productView)) {
      return _BlockedView(
        icon: Icons.visibility_off_outlined,
        title: 'Bạn chưa có quyền xem quản lý sản phẩm',
        message: 'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền.',
        actionLabel: 'Về tổng quan',
        onAction: () => context.goNamed(
          RouteNames.storeOverview,
          pathParameters: {'storeId': storeId.toString()},
        ),
      );
    }

    final access = ProductManagementAccess(
      storeId: storeId,
      canViewProduct: accessState.can(AppPermissionCodes.productView),
      canCreateProduct: accessState.can(AppPermissionCodes.productCreate),
      canUpdateProduct: accessState.can(AppPermissionCodes.productUpdate),
      canDeleteProduct: accessState.can(AppPermissionCodes.productDelete),
    );
    final state = ref.watch(productManagementNotifierProvider(access));
    final notifier = ref.read(
      productManagementNotifierProvider(access).notifier,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _ProductFab(
        state: state,
        access: access,
        onCreateProduct: () =>
            _openProductCreatePage(context, access, state, notifier),
        onManageCategories: () => _showCategoryManagement(context, access),
      ),
      body: Column(
        children: [
          _ProductManagementHeader(
            storeId: storeId,
            onQueryChanged: notifier.setQuery,
          ),
          _ProductManagementTabs(
            selectedTab: state.selectedTab,
            onSelected: (tab) {
              if (tab == ProductManagementTab.inventory ||
                  tab == ProductManagementTab.addOns) {
                _showComingSoon(context, tab.label);
                return;
              }

              notifier.setTab(tab);
            },
          ),
          Expanded(
            child: switch (state.status) {
              ProductManagementStatus.initial ||
              ProductManagementStatus.loading => const _LoadingView(),
              ProductManagementStatus.forbidden => _BlockedView(
                icon: Icons.visibility_off_outlined,
                title: 'Bạn chưa có quyền xem quản lý sản phẩm',
                message:
                    state.errorMessage ??
                    'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền.',
                actionLabel: 'Về tổng quan',
                onAction: () => context.goNamed(
                  RouteNames.storeOverview,
                  pathParameters: {'storeId': storeId.toString()},
                ),
              ),
              ProductManagementStatus.error => _BlockedView(
                icon: Icons.error_outline_rounded,
                title: 'Không thể tải quản lý sản phẩm',
                message: state.errorMessage ?? 'Vui lòng thử lại sau.',
                actionLabel: 'Thử lại',
                onAction: notifier.load,
              ),
              ProductManagementStatus.ready => _ReadyContent(
                state: state,
                access: access,
                onRefresh: notifier.load,
                onCategorySelected: notifier.selectCategory,
                onManageCategories: () =>
                    _showCategoryManagement(context, access),
                onOpenProduct: (product) =>
                    _openProductDetail(context, notifier, state, product),
                onEditCategory: (category) =>
                    _showCategoryForm(context, ref, access, category: category),
                onDeleteCategory: (category) =>
                    _confirmDeleteCategory(context, ref, access, category),
              ),
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openProductDetail(
    BuildContext context,
    ProductManagementNotifier notifier,
    ProductManagementState state,
    Product product,
  ) async {
    final changed = await context.pushNamed<bool>(
      RouteNames.storeProductDetail,
      pathParameters: {
        'storeId': storeId.toString(),
        'productId': product.id.toString(),
      },
      extra: ProductCreateSeedData(
        categories: state.categories,
        toppings: state.toppings,
        editingProductId: product.id,
        editingProduct: product,
      ),
    );

    if (changed == true) {
      await notifier.load();
    }
  }

  Future<void> _openProductCreatePage(
    BuildContext context,
    ProductManagementAccess access,
    ProductManagementState state,
    ProductManagementNotifier notifier,
  ) async {
    if (!access.canCreateProduct) {
      _showMessage(context, 'Bạn chưa có quyền thêm sản phẩm');
      return;
    }

    final created = await context.pushNamed<bool>(
      RouteNames.storeProductCreate,
      pathParameters: {'storeId': access.storeId.toString()},
      extra: ProductCreateSeedData(
        categories: state.categories,
        toppings: state.toppings,
      ),
    );
    if (created == true) {
      await notifier.load();
    }
  }

  Future<void> _showCategoryManagement(
    BuildContext context,
    ProductManagementAccess access,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: _CategoryManagementBottomSheet(access: access),
        );
      },
    );
  }

  Future<void> _showCategoryForm(
    BuildContext context,
    WidgetRef ref,
    ProductManagementAccess access, {
    ProductCategory? category,
  }) async {
    final canSubmit = category == null
        ? access.canCreateProduct
        : access.canUpdateProduct;
    if (!canSubmit) {
      _showMessage(
        context,
        category == null
            ? 'Bạn chưa có quyền thêm danh mục'
            : 'Bạn chưa có quyền cập nhật danh mục',
      );
      return;
    }

    final notifier = ref.read(
      productManagementNotifierProvider(access).notifier,
    );

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CategoryFormBottomSheet(
          category: category,
          onSubmit: (name) {
            if (category == null) {
              return notifier.createCategory(name: name);
            }

            return notifier.updateCategory(categoryId: category.id, name: name);
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    ProductManagementAccess access,
    ProductCategory category,
  ) async {
    if (!access.canDeleteProduct) {
      _showMessage(context, 'Bạn chưa có quyền xóa danh mục');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa danh mục?'),
          content: Text('Danh mục "${category.name}" sẽ bị xóa khỏi cửa hàng.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              key: const Key('confirm_delete_product_category_button'),
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(productManagementNotifierProvider(access).notifier)
          .deleteCategory(category.id);
      if (context.mounted) {
        _showMessage(context, 'Đã xóa danh mục');
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, _cleanError(error));
      }
    }
  }
}

class _ProductFab extends StatelessWidget {
  final ProductManagementState state;
  final ProductManagementAccess access;
  final VoidCallback onCreateProduct;
  final VoidCallback onManageCategories;

  const _ProductFab({
    required this.state,
    required this.access,
    required this.onCreateProduct,
    required this.onManageCategories,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status != ProductManagementStatus.ready) {
      return const SizedBox.shrink();
    }

    final isProductTab = state.selectedTab == ProductManagementTab.products;
    final isCategoryTab = state.selectedTab == ProductManagementTab.categories;
    final canUseFab = isProductTab
        ? access.canCreateProduct
        : access.canCreateProduct ||
              access.canUpdateProduct ||
              access.canDeleteProduct;
    if ((!isProductTab && !isCategoryTab) || !canUseFab) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      key: Key(isProductTab ? 'add_product_button' : 'add_category_button'),
      onPressed: isProductTab ? onCreateProduct : onManageCategories,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.surface,
      child: Icon(isProductTab ? Icons.add_rounded : Icons.grid_view_rounded),
    );
  }
}

class _ReadyContent extends StatelessWidget {
  final ProductManagementState state;
  final ProductManagementAccess access;
  final Future<void> Function() onRefresh;
  final ValueChanged<int?> onCategorySelected;
  final VoidCallback onManageCategories;
  final ValueChanged<Product> onOpenProduct;
  final ValueChanged<ProductCategory> onEditCategory;
  final ValueChanged<ProductCategory> onDeleteCategory;

  const _ReadyContent({
    required this.state,
    required this.access,
    required this.onRefresh,
    required this.onCategorySelected,
    required this.onManageCategories,
    required this.onOpenProduct,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: switch (state.selectedTab) {
        ProductManagementTab.products => _ProductsTabContent(
          state: state,
          onManageCategoriesTap: onManageCategories,
          onCategorySelected: onCategorySelected,
          onProductTap: onOpenProduct,
        ),
        ProductManagementTab.categories => _CategoriesTabContent(
          categories: state.visibleCategories,
          canUpdateCategory: access.canUpdateProduct,
          canDeleteCategory: access.canDeleteProduct,
          onEditCategory: onEditCategory,
          onDeleteCategory: onDeleteCategory,
        ),
        ProductManagementTab.inventory ||
        ProductManagementTab.addOns => const _ComingSoonTab(),
      },
    );
  }
}

class _ProductManagementHeader extends StatelessWidget {
  final int storeId;
  final ValueChanged<String> onQueryChanged;

  const _ProductManagementHeader({
    required this.storeId,
    required this.onQueryChanged,
  });

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
              RouteNames.storeOverview,
              pathParameters: {'storeId': storeId.toString()},
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                key: const Key('product_management_search_field'),
                onChanged: onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm tên sản phẩm, danh mục',
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
            ),
          ),
          const SizedBox(width: AppConstants.spacingXs),
          IconButton(
            tooltip: 'Sắp xếp',
            icon: const Icon(Icons.sort_rounded),
            color: AppColors.textSecondary,
            onPressed: () => _showComingSoon(context, 'Sắp xếp'),
          ),
          IconButton(
            tooltip: 'Kiểu hiển thị',
            icon: const Icon(Icons.list_rounded),
            color: AppColors.textSecondary,
            onPressed: () => _showComingSoon(context, 'Kiểu hiển thị'),
          ),
        ],
      ),
    );
  }
}

class _ProductManagementTabs extends StatelessWidget {
  final ProductManagementTab selectedTab;
  final ValueChanged<ProductManagementTab> onSelected;

  const _ProductManagementTabs({
    required this.selectedTab,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Row(
        children: [
          for (final tab in ProductManagementTab.values)
            Expanded(
              child: InkWell(
                key: Key('product_management_tab_${tab.name}'),
                onTap: () => onSelected(tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selectedTab == tab
                            ? AppColors.primary
                            : AppColors.border,
                        width: selectedTab == tab ? 2.5 : 1,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      color: selectedTab == tab
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontWeight: selectedTab == tab
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductsTabContent extends StatelessWidget {
  final ProductManagementState state;
  final VoidCallback onManageCategoriesTap;
  final ValueChanged<int?> onCategorySelected;
  final ValueChanged<Product> onProductTap;

  const _ProductsTabContent({
    required this.state,
    required this.onManageCategoriesTap,
    required this.onCategorySelected,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final products = state.visibleProducts;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingXxl,
      ),
      children: [
        _CategoryFilterChips(
          categories: state.categories,
          selectedCategoryId: state.selectedCategoryId,
          onSelected: onCategorySelected,
          onManageCategoriesTap: onManageCategoriesTap,
        ),
        const SizedBox(height: AppConstants.spacingMd),
        if (state.categories.isEmpty)
          const _EmptyState(
            icon: Icons.category_outlined,
            title: 'Chưa có danh mục',
            message: 'Hãy tạo danh mục trước khi thêm sản phẩm.',
          )
        else if (products.isEmpty)
          const _EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Chưa có sản phẩm phù hợp',
            message: 'Hãy thử đổi từ khóa hoặc danh mục đang lọc.',
          )
        else
          for (final product in products) ...[
            _ProductTile(product: product, onTap: () => onProductTap(product)),
            const SizedBox(height: AppConstants.spacingSm),
          ],
      ],
    );
  }
}

class _CategoryFilterChips extends StatelessWidget {
  final List<ProductCategory> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;
  final VoidCallback onManageCategoriesTap;

  const _CategoryFilterChips({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    required this.onManageCategoriesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: OutlinedButton(
            key: const Key('manage_product_categories_button'),
            onPressed: onManageCategoriesTap,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(42, 42),
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Icon(Icons.grid_view_rounded, size: 19),
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: SingleChildScrollView(
            key: const Key('product_category_chips_scroll_view'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipButton(
                  label: 'Tất cả',
                  isSelected: selectedCategoryId == null,
                  onTap: () => onSelected(null),
                ),
                for (final category in categories) ...[
                  const SizedBox(width: AppConstants.spacingSm),
                  _FilterChipButton(
                    label: category.name,
                    isSelected: selectedCategoryId == category.id,
                    onTap: () => onSelected(category.id),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
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
      child: Text(label),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        key: Key('product_tile_${product.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingSm),
          child: Row(
            children: [
              _ProductThumbnail(imageUrl: product.imageUrl),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingXs),
                        _ProductStatusBadge(isActive: product.isActive),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      [
                        product.categoryName.isEmpty
                            ? product.type.label
                            : product.categoryName,
                        if (product.preparationTime > 0)
                          '${product.preparationTime} phút',
                      ].join(' | '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      _formatCurrency(product.price),
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (product.isTrackInventory &&
                        product.inventoryDeductionMode !=
                            InventoryDeductionMode.recipeOnly) ...[
                      const SizedBox(height: AppConstants.spacingXs),
                      _ProductInventoryStatus(product: product),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductStatusBadge extends StatelessWidget {
  final bool isActive;

  const _ProductStatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingXs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryLight : AppColors.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        isActive ? 'Đang hoạt động' : 'Tạm ngưng',
        style: AppTextStyles.caption.copyWith(
          color: isActive ? AppColors.success : AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProductInventoryStatus extends StatelessWidget {
  final Product product;

  const _ProductInventoryStatus({required this.product});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch ((product.isOutOfStock, product.isLowStock)) {
      (true, _) => ('Hết hàng', AppColors.error),
      (_, true) => ('Sắp hết hàng', AppColors.warning),
      _ => ('Tồn: ${_formatStock(product.quantity)}', AppColors.textSecondary),
    };

    return Text(label, style: AppTextStyles.caption.copyWith(color: color));
  }
}

class _ProductThumbnail extends StatelessWidget {
  final String imageUrl;

  const _ProductThumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final canLoadNetworkImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        width: 84,
        height: 84,
        color: AppColors.muted,
        child: canLoadNetworkImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _ProductPlaceholderIcon(),
              )
            : const _ProductPlaceholderIcon(),
      ),
    );
  }
}

class _ProductPlaceholderIcon extends StatelessWidget {
  const _ProductPlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.fastfood_outlined,
      color: AppColors.textDisabled,
      size: 32,
    );
  }
}

class _CategoriesTabContent extends StatelessWidget {
  final List<ProductCategory> categories;
  final bool canUpdateCategory;
  final bool canDeleteCategory;
  final ValueChanged<ProductCategory> onEditCategory;
  final ValueChanged<ProductCategory> onDeleteCategory;

  const _CategoriesTabContent({
    required this.categories,
    required this.canUpdateCategory,
    required this.canDeleteCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingXxl,
      ),
      children: [
        Text(
          'Danh mục sản phẩm',
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        if (categories.isEmpty)
          const _EmptyState(
            icon: Icons.category_outlined,
            title: 'Chưa có danh mục',
            message: 'Danh mục mới sẽ xuất hiện tại đây.',
          )
        else
          for (final category in categories) ...[
            _CategoryTile(
              category: category,
              canUpdateCategory: canUpdateCategory,
              canDeleteCategory: canDeleteCategory,
              onEdit: () => onEditCategory(category),
              onDelete: () => onDeleteCategory(category),
            ),
            const SizedBox(height: AppConstants.spacingSm),
          ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ProductCategory category;
  final bool canUpdateCategory;
  final bool canDeleteCategory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.canUpdateCategory,
    required this.canDeleteCategory,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: Key('product_category_tile_${category.id}'),
        leading: const CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          child: Icon(Icons.category_outlined),
        ),
        title: Text(
          category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
        ),
        trailing: PopupMenuButton<_CategoryAction>(
          tooltip: 'Thao tác danh mục',
          onSelected: (action) {
            switch (action) {
              case _CategoryAction.edit:
                onEdit();
              case _CategoryAction.delete:
                onDelete();
            }
          },
          itemBuilder: (context) {
            return [
              PopupMenuItem<_CategoryAction>(
                enabled: canUpdateCategory,
                value: _CategoryAction.edit,
                child: const Text('Sửa tên'),
              ),
              PopupMenuItem<_CategoryAction>(
                enabled: canDeleteCategory,
                value: _CategoryAction.delete,
                child: const Text('Xóa danh mục'),
              ),
            ];
          },
        ),
      ),
    );
  }
}

enum _CategoryAction { edit, delete }

class _CategoryManagementBottomSheet extends ConsumerStatefulWidget {
  final ProductManagementAccess access;

  const _CategoryManagementBottomSheet({required this.access});

  @override
  ConsumerState<_CategoryManagementBottomSheet> createState() =>
      _CategoryManagementBottomSheetState();
}

class _CategoryManagementBottomSheetState
    extends ConsumerState<_CategoryManagementBottomSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isEditing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productManagementNotifierProvider(widget.access));
    final categories = _filterCategories(state.categories);
    final canEditList =
        widget.access.canUpdateProduct || widget.access.canDeleteProduct;

    return SafeArea(
      key: const Key('product_category_management_sheet'),
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.spacingMd),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingMd,
                AppConstants.spacingSm,
                AppConstants.spacingMd,
                AppConstants.spacingSm,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('edit_product_categories_button'),
                      onPressed: canEditList
                          ? () => setState(() => _isEditing = !_isEditing)
                          : null,
                      icon: Icon(
                        _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                        size: 20,
                      ),
                      label: Text(_isEditing ? 'Xong' : 'Chỉnh sửa'),
                    ),
                  ),
                  Text(
                    'Danh mục',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      key: const Key(
                        'close_product_category_management_button',
                      ),
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                AppConstants.spacingMd,
                AppConstants.spacingLg,
                AppConstants.spacingMd,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key(
                        'product_category_management_search_field',
                      ),
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Tìm tên danh mục',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: IconButton.filled(
                      key: const Key('add_product_category_button'),
                      tooltip: 'Thêm danh mục',
                      onPressed: widget.access.canCreateProduct
                          ? () => _showCategoryForm(context)
                          : null,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Expanded(
              child: _CategoryManagementList(
                categories: categories,
                isEditing: _isEditing,
                canUpdateCategory: widget.access.canUpdateProduct,
                canDeleteCategory: widget.access.canDeleteProduct,
                onSelected: (category) {
                  ref
                      .read(
                        productManagementNotifierProvider(
                          widget.access,
                        ).notifier,
                      )
                      .selectCategory(category.id);
                  Navigator.of(context).pop();
                },
                onEdit: (category) =>
                    _showCategoryForm(context, category: category),
                onDelete: _confirmDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ProductCategory> _filterCategories(List<ProductCategory> categories) {
    if (_query.isEmpty) {
      return categories;
    }

    final query = _query.toLowerCase();
    return categories
        .where((category) => category.name.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _showCategoryForm(
    BuildContext context, {
    ProductCategory? category,
  }) async {
    final canSubmit = category == null
        ? widget.access.canCreateProduct
        : widget.access.canUpdateProduct;
    if (!canSubmit) {
      _showMessage(
        context,
        category == null
            ? 'Bạn chưa có quyền thêm danh mục'
            : 'Bạn chưa có quyền cập nhật danh mục',
      );
      return;
    }

    final notifier = ref.read(
      productManagementNotifierProvider(widget.access).notifier,
    );

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CategoryFormBottomSheet(
          category: category,
          onSubmit: (name) {
            if (category == null) {
              return notifier.createCategory(name: name);
            }

            return notifier.updateCategory(categoryId: category.id, name: name);
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(ProductCategory category) async {
    if (!widget.access.canDeleteProduct) {
      _showMessage(context, 'Bạn chưa có quyền xóa danh mục');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa danh mục?'),
          content: Text('Danh mục "${category.name}" sẽ bị xóa khỏi cửa hàng.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              key: const Key('confirm_delete_product_category_button'),
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(productManagementNotifierProvider(widget.access).notifier)
          .deleteCategory(category.id);
      if (mounted) {
        _showMessage(context, 'Đã xóa danh mục');
      }
    } catch (error) {
      if (mounted) {
        _showMessage(context, _cleanError(error));
      }
    }
  }
}

class _CategoryManagementList extends StatelessWidget {
  final List<ProductCategory> categories;
  final bool isEditing;
  final bool canUpdateCategory;
  final bool canDeleteCategory;
  final ValueChanged<ProductCategory> onSelected;
  final ValueChanged<ProductCategory> onEdit;
  final ValueChanged<ProductCategory> onDelete;

  const _CategoryManagementList({
    required this.categories,
    required this.isEditing,
    required this.canUpdateCategory,
    required this.canDeleteCategory,
    required this.onSelected,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const _EmptyState(
        icon: Icons.category_outlined,
        title: 'Chưa có danh mục',
        message: 'Thêm danh mục để nhóm sản phẩm trong cửa hàng.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingLg,
        0,
        AppConstants.spacingLg,
        AppConstants.spacingXl,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryManagementTile(
          key: ValueKey('category_management_${category.id}'),
          category: category,
          isEditing: isEditing,
          canUpdateCategory: canUpdateCategory,
          canDeleteCategory: canDeleteCategory,
          onSelected: onSelected,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.spacingSm),
      itemCount: categories.length,
    );
  }
}

class _CategoryManagementTile extends StatelessWidget {
  final ProductCategory category;
  final bool isEditing;
  final bool canUpdateCategory;
  final bool canDeleteCategory;
  final ValueChanged<ProductCategory> onSelected;
  final ValueChanged<ProductCategory> onEdit;
  final ValueChanged<ProductCategory> onDelete;

  const _CategoryManagementTile({
    super.key,
    required this.category,
    required this.isEditing,
    required this.canUpdateCategory,
    required this.canDeleteCategory,
    required this.onSelected,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        key: Key('category_management_tile_${category.id}'),
        onTap: isEditing ? null : () => onSelected(category),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingSm,
            vertical: AppConstants.spacingSm,
          ),
          child: Row(
            children: [
              if (isEditing)
                IconButton(
                  key: Key('delete_product_category_${category.id}'),
                  tooltip: canDeleteCategory
                      ? 'Xóa danh mục'
                      : 'Không có quyền xóa',
                  onPressed: canDeleteCategory
                      ? () => onDelete(category)
                      : null,
                  color: AppColors.error,
                  icon: const Icon(Icons.remove_circle_rounded),
                )
              else
                const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primary,
                  child: Icon(Icons.category_outlined),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSm,
                  ),
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (isEditing)
                IconButton(
                  key: Key('edit_product_category_${category.id}'),
                  tooltip: canUpdateCategory
                      ? 'Chỉnh sửa danh mục'
                      : 'Không có quyền chỉnh sửa',
                  onPressed: canUpdateCategory ? () => onEdit(category) : null,
                  color: AppColors.primary,
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFormBottomSheet extends StatefulWidget {
  final ProductCategory? category;
  final Future<void> Function(String name) onSubmit;

  const _CategoryFormBottomSheet({this.category, required this.onSubmit});

  @override
  State<_CategoryFormBottomSheet> createState() =>
      _CategoryFormBottomSheetState();
}

class _CategoryFormBottomSheetState extends State<_CategoryFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetFrame(
      title: widget.category == null ? 'Thêm danh mục' : 'Sửa danh mục',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('category_name_field'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên danh mục'),
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên danh mục';
                }

                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('category_form_submit_button'),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_nameController.text.trim());
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(context, _cleanError(error));
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _BottomSheetFrame extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheetFrame({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          AppConstants.spacingLg,
          AppConstants.spacingMd,
          AppConstants.spacingLg,
          AppConstants.spacingLg + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.w700,
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
              const SizedBox(height: AppConstants.spacingMd),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      children: const [
        _EmptyState(
          icon: Icons.construction_outlined,
          title: 'Sắp triển khai',
          message: 'Tab này sẽ được bổ sung ở phiên bản sau.',
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLg,
        vertical: AppConstants.spacingXxl,
      ),
      child: Column(
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

String _formatCurrency(int value) {
  return '${NumberFormat.decimalPattern('vi_VN').format(value)} đ';
}

String _formatStock(double value) =>
    NumberFormat.decimalPattern('vi_VN').format(value);

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}

void _showComingSoon(BuildContext context, String feature) {
  _showMessage(context, '$feature sẽ được triển khai sau');
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
