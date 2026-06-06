import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product_type.dart';
import '../providers/product_management_providers.dart';
import 'product_management_state.dart';

class ProductManagementNotifier
    extends
        AutoDisposeFamilyNotifier<
          ProductManagementState,
          ProductManagementAccess
        > {
  late final ProductManagementAccess _access;
  bool _initialLoadStarted = false;

  @override
  ProductManagementState build(ProductManagementAccess arg) {
    _access = arg;
    Future.microtask(load);
    return const ProductManagementState.initial();
  }

  Future<void> load() async {
    if (_initialLoadStarted &&
        state.status == ProductManagementStatus.loading) {
      return;
    }

    _initialLoadStarted = true;

    if (!_access.canViewProduct) {
      state = state.copyWith(
        status: ProductManagementStatus.forbidden,
        errorMessage: 'Bạn chưa có quyền xem quản lý sản phẩm',
      );
      return;
    }

    state = state.copyWith(
      status: ProductManagementStatus.loading,
      clearError: true,
    );

    try {
      final categories = await ref.read(loadProductCategoriesUseCaseProvider)(
        _access.storeId,
      );
      final products = await ref.read(loadProductsUseCaseProvider)(
        _access.storeId,
      );

      state = state.copyWith(
        status: ProductManagementStatus.ready,
        categories: categories,
        products: products,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: ProductManagementStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> createCategory({required String name}) async {
    _ensureAllowed(_access.canCreateProduct, 'Bạn chưa có quyền thêm danh mục');

    await ref.read(createProductCategoryUseCaseProvider)(
      storeId: _access.storeId,
      name: name,
    );
    await load();
  }

  Future<void> updateCategory({
    required int categoryId,
    required String name,
  }) async {
    _ensureAllowed(
      _access.canUpdateProduct,
      'Bạn chưa có quyền cập nhật danh mục',
    );

    await ref.read(updateProductCategoryUseCaseProvider)(
      categoryId: categoryId,
      name: name,
    );
    await load();
  }

  Future<void> deleteCategory(int categoryId) async {
    _ensureAllowed(_access.canDeleteProduct, 'Bạn chưa có quyền xóa danh mục');

    await ref.read(deleteProductCategoryUseCaseProvider)(categoryId);
    if (state.selectedCategoryId == categoryId) {
      state = state.copyWith(clearSelectedCategory: true);
    }
    await load();
  }

  Future<void> createProduct({
    required int categoryId,
    required String name,
    required String imageUrl,
    required String description,
    required int preparationTime,
    required int price,
    required ProductType type,
  }) async {
    _ensureAllowed(_access.canCreateProduct, 'Bạn chưa có quyền thêm sản phẩm');

    await ref.read(createProductUseCaseProvider)(
      storeId: _access.storeId,
      categoryId: categoryId,
      name: name,
      imageUrl: imageUrl,
      description: description,
      preparationTime: preparationTime,
      price: price,
      type: type,
      variants: null,
      toppingIds: const [],
    );
    await load();
  }

  Future<void> updateProductSellStatus({
    required int productId,
    required bool isSell,
  }) async {
    _ensureAllowed(
      _access.canUpdateProduct,
      'Bạn chưa có quyền cập nhật sản phẩm',
    );

    await ref.read(updateProductSellStatusUseCaseProvider)(
      productId: productId,
      isSell: isSell,
    );
    await load();
  }

  Future<void> deleteProduct(int productId) async {
    _ensureAllowed(_access.canDeleteProduct, 'Bạn chưa có quyền xóa sản phẩm');

    await ref.read(deleteProductUseCaseProvider)(productId);
    await load();
  }

  void setTab(ProductManagementTab tab) {
    if (state.selectedTab == tab) {
      return;
    }

    state = state.copyWith(selectedTab: tab);
  }

  void selectCategory(int? categoryId) {
    if (state.selectedCategoryId == categoryId) {
      return;
    }

    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearSelectedCategory: categoryId == null,
    );
  }

  void setQuery(String query) {
    state = state.copyWith(query: query.trim());
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _ensureAllowed(bool isAllowed, String message) {
    if (!isAllowed) {
      throw Exception(message);
    }
  }
}
