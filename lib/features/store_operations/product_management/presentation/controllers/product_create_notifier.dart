import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    Future.microtask(load);
    return const ProductCreateState.initial();
  }

  Future<void> load() async {
    if (_initialLoadStarted && state.status == ProductCreateStatus.loading) {
      return;
    }

    _initialLoadStarted = true;

    if (!_access.canCreateProduct) {
      state = state.copyWith(
        status: ProductCreateStatus.forbidden,
        errorMessage: 'Bạn chưa có quyền thêm sản phẩm',
      );
      return;
    }

    state = state.copyWith(
      status: ProductCreateStatus.loading,
      clearError: true,
    );

    try {
      final categories = await ref.read(loadProductCategoriesUseCaseProvider)(
        _access.storeId,
      );
      final toppings = await ref.read(loadProductToppingsUseCaseProvider)(
        _access.storeId,
      );

      state = state.copyWith(
        status: ProductCreateStatus.ready,
        categories: categories,
        toppings: toppings,
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

  List<ProductVariantDraft> _validatedVariants(
    List<ProductVariantDraft> variants,
  ) {
    final cleanVariants = variants
        .where((variant) => variant.name.trim().isNotEmpty && variant.price > 0)
        .toList();

    if (cleanVariants.isEmpty) {
      throw Exception('Vui lòng nhập ít nhất một size hợp lệ');
    }

    if (!cleanVariants.any((variant) => variant.isDefault)) {
      throw Exception('Vui lòng chọn size mặc định');
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
