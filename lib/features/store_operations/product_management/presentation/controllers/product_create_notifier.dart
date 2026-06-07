import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product_category.dart';
import '../../domain/entities/product_topping.dart';
import '../../domain/entities/product_variant_draft.dart';
import '../providers/product_management_providers.dart';
import 'product_create_state.dart';

class ProductCreateNotifier
    extends AutoDisposeFamilyNotifier<ProductCreateState, ProductCreateAccess> {
  late final ProductCreateAccess _access;
  bool _initialLoadStarted = false;

  @override
  ProductCreateState build(ProductCreateAccess arg) {
    _access = arg;
    final seedData = arg.seedData;
    if (seedData != null && seedData.isEditing) {
      Future.microtask(load);
      return ProductCreateState(
        status: ProductCreateStatus.loading,
        categories: seedData.categories,
        toppings: seedData.toppings,
        editingProduct: seedData.editingProduct,
      );
    }

    if (arg.canCreateProduct && seedData != null) {
      return ProductCreateState(
        status: ProductCreateStatus.ready,
        categories: seedData.categories,
        toppings: seedData.toppings,
      );
    }

    Future.microtask(load);
    return const ProductCreateState.initial();
  }

  Future<void> load() async {
    if (_initialLoadStarted && state.status == ProductCreateStatus.loading) {
      return;
    }

    _initialLoadStarted = true;

    final isEditing = _access.seedData?.isEditing ?? false;
    final canLoad = isEditing
        ? _access.canUpdateProduct
        : _access.canCreateProduct;
    if (!canLoad) {
      state = state.copyWith(
        status: ProductCreateStatus.forbidden,
        errorMessage: isEditing
            ? 'Bạn chưa có quyền cập nhật sản phẩm'
            : 'Bạn chưa có quyền thêm sản phẩm',
      );
      return;
    }

    state = state.copyWith(
      status: ProductCreateStatus.loading,
      clearError: true,
    );

    try {
      final seedData = _access.seedData;
      final categories = seedData?.categories.isNotEmpty == true
          ? seedData!.categories
          : await ref.read(loadProductCategoriesUseCaseProvider)(
              _access.storeId,
            );
      final toppings = seedData?.toppings.isNotEmpty == true
          ? seedData!.toppings
          : await ref.read(loadProductToppingsUseCaseProvider)(_access.storeId);
      final editingProductId =
          seedData?.editingProductId ?? seedData?.editingProduct?.id;
      final editingProduct = editingProductId == null
          ? null
          : await ref.read(loadProductDetailUseCaseProvider)(editingProductId);

      state = state.copyWith(
        status: ProductCreateStatus.ready,
        categories: categories,
        toppings: toppings,
        editingProduct: editingProduct,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: ProductCreateStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> submit(ProductCreateInput input) async {
    _ensureAllowed(_access.canCreateProduct, 'Bạn chưa có quyền thêm sản phẩm');

    final cleanName = input.name.trim();
    if (cleanName.isEmpty) {
      throw Exception('Vui lòng nhập tên món');
    }

    if (!state.categories.any((category) => category.id == input.categoryId)) {
      throw Exception('Vui lòng chọn danh mục');
    }

    final variants = input.hasMultipleSizes
        ? _validatedVariants(input.variants)
        : null;
    final price = _resolvePrice(input.basePrice, variants);

    state = state.copyWith(
      status: ProductCreateStatus.submitting,
      clearError: true,
    );

    try {
      await ref.read(createProductUseCaseProvider)(
        storeId: _access.storeId,
        categoryId: input.categoryId,
        name: cleanName,
        imageUrl: '',
        description: input.description.trim(),
        preparationTime: input.preparationTime,
        price: price,
        type: input.type,
        variants: variants,
        toppingIds: input.toppingIds,
      );
      state = state.copyWith(
        status: ProductCreateStatus.success,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: ProductCreateStatus.ready,
        errorMessage: _cleanError(error),
      );
      rethrow;
    }
  }

  Future<void> update(ProductCreateInput input) async {
    _ensureAllowed(
      _access.canUpdateProduct,
      'Bạn chưa có quyền cập nhật sản phẩm',
    );

    final editingProduct = state.editingProduct;
    if (editingProduct == null) {
      throw Exception('Không tìm thấy sản phẩm cần cập nhật');
    }

    final cleanName = input.name.trim();
    if (cleanName.isEmpty) {
      throw Exception('Vui lòng nhập tên món');
    }

    if (!state.categories.any((category) => category.id == input.categoryId)) {
      throw Exception('Vui lòng chọn danh mục');
    }

    final variants = _resolvedUpdateVariants(input);
    final price = _resolvePrice(input.basePrice, variants);

    state = state.copyWith(
      status: ProductCreateStatus.submitting,
      clearError: true,
    );

    try {
      final product = await ref.read(updateProductUseCaseProvider)(
        productId: editingProduct.id,
        categoryId: input.categoryId,
        name: cleanName,
        imageUrl: editingProduct.imageUrl,
        description: input.description.trim(),
        preparationTime: input.preparationTime,
        price: price,
        type: input.type,
        variants: variants,
        toppingIds: input.toppingIds,
      );
      state = state.copyWith(
        status: ProductCreateStatus.success,
        editingProduct: product,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: ProductCreateStatus.ready,
        errorMessage: _cleanError(error),
      );
      rethrow;
    }
  }

  Future<void> deleteProduct() async {
    _ensureAllowed(_access.canDeleteProduct, 'Bạn chưa có quyền xóa sản phẩm');

    final editingProduct = state.editingProduct;
    if (editingProduct == null) {
      throw Exception('Không tìm thấy sản phẩm cần xóa');
    }

    await ref.read(deleteProductUseCaseProvider)(editingProduct.id);
    state = state.copyWith(
      status: ProductCreateStatus.success,
      clearError: true,
    );
  }

  Future<ProductCategory> createCategory({required String name}) async {
    _ensureAllowed(_access.canCreateProduct, 'Bạn chưa có quyền thêm danh mục');

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('Vui lòng nhập tên danh mục');
    }

    final category = await ref.read(createProductCategoryUseCaseProvider)(
      storeId: _access.storeId,
      name: cleanName,
    );

    state = state.copyWith(
      categories: [...state.categories, category],
      clearError: true,
    );
    return category;
  }

  Future<ProductTopping> createTopping({
    required String name,
    required int price,
  }) async {
    _ensureAllowed(_access.canCreateProduct, 'Bạn chưa có quyền thêm topping');

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('Vui lòng nhập tên topping');
    }

    if (price < 0) {
      throw Exception('Vui lòng nhập giá topping hợp lệ');
    }

    final topping = await ref.read(createProductToppingUseCaseProvider)(
      storeId: _access.storeId,
      name: cleanName,
      price: price,
    );

    state = state.copyWith(toppings: [...state.toppings, topping]);
    return topping;
  }

  Future<ProductTopping> updateTopping({
    required int toppingId,
    required String name,
    required int price,
  }) async {
    _ensureAllowed(
      _access.canUpdateProduct,
      'Bạn chưa có quyền cập nhật topping',
    );

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('Vui lòng nhập tên topping');
    }

    if (price < 0) {
      throw Exception('Vui lòng nhập giá topping hợp lệ');
    }

    final topping = await ref.read(updateProductToppingUseCaseProvider)(
      toppingId: toppingId,
      name: cleanName,
      price: price,
    );

    state = state.copyWith(
      toppings: [
        for (final item in state.toppings)
          if (item.id == toppingId) topping else item,
      ],
      clearError: true,
    );
    return topping;
  }

  Future<void> deleteTopping(int toppingId) async {
    _ensureAllowed(_access.canDeleteProduct, 'Bạn chưa có quyền xóa topping');

    await ref.read(deleteProductToppingUseCaseProvider)(toppingId);
    state = state.copyWith(
      toppings: state.toppings
          .where((topping) => topping.id != toppingId)
          .toList(),
      clearError: true,
    );
  }

  List<ProductVariantDraft> _validatedVariants(
    List<ProductVariantDraft> variants,
  ) {
    final cleanVariants = variants
        .where((variant) => variant.name.trim().isNotEmpty && variant.price > 0)
        .toList();

    if (cleanVariants.isEmpty) {
      throw Exception('Vui lòng nhập ít nhất một tùy chọn hợp lệ');
    }

    return cleanVariants;
  }

  List<ProductVariantDraft> _resolvedUpdateVariants(ProductCreateInput input) {
    if (!input.hasMultipleSizes || input.variants.isEmpty) {
      return const [];
    }

    return _validatedStrictVariants(input.variants);
  }

  List<ProductVariantDraft> _validatedStrictVariants(
    List<ProductVariantDraft> variants,
  ) {
    final cleanVariants = <ProductVariantDraft>[];

    for (final variant in variants) {
      final cleanName = variant.name.trim();
      if (cleanName.isEmpty || variant.price <= 0) {
        throw Exception('Vui lòng nhập đầy đủ tên và giá tùy chọn');
      }

      cleanVariants.add(
        ProductVariantDraft(
          name: cleanName,
          price: variant.price,
          isDefault: variant.isDefault,
        ),
      );
    }

    return cleanVariants;
  }

  int _resolvePrice(int? basePrice, List<ProductVariantDraft>? variants) {
    if (basePrice != null && basePrice > 0) {
      return basePrice;
    }

    if (variants != null && variants.isNotEmpty) {
      return variants
          .firstWhere(
            (variant) => variant.isDefault,
            orElse: () => variants.first,
          )
          .price;
    }

    throw Exception('Vui lòng nhập giá cơ bản');
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
