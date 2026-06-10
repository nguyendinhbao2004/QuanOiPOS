import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product_category.dart';
import '../../domain/entities/product_ingredient.dart';
import '../../domain/entities/product_recipe_draft.dart';
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
        ingredients: seedData.ingredients,
        editingProduct: seedData.editingProduct,
      );
    }

    if (arg.canCreateProduct && seedData != null) {
      if (seedData.ingredients.isEmpty) {
        Future.microtask(load);
      }
      return ProductCreateState(
        status: ProductCreateStatus.ready,
        categories: seedData.categories,
        toppings: seedData.toppings,
        ingredients: seedData.ingredients,
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
      final ingredients = seedData?.ingredients.isNotEmpty == true
          ? seedData!.ingredients
          : await ref.read(loadProductIngredientsUseCaseProvider)(
              _access.storeId,
            );
      final editingProductId =
          seedData?.editingProductId ?? seedData?.editingProduct?.id;
      final editingProduct = editingProductId == null
          ? null
          : await ref.read(loadProductDetailUseCaseProvider)(editingProductId);

      state = state.copyWith(
        status: ProductCreateStatus.ready,
        categories: categories,
        toppings: toppings,
        ingredients: ingredients,
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
    final costPrice = _resolveCostPrice(input.costPrice, variants);
    final recipes = _validatedRecipes(input.recipes);

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
        costPrice: costPrice,
        type: input.type,
        variants: variants,
        toppingIds: input.toppingIds,
        recipes: recipes,
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
    final costPrice = _resolveCostPrice(input.costPrice, variants);
    final recipes = _validatedRecipes(input.recipes);

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
        costPrice: costPrice,
        type: input.type,
        variants: variants,
        toppingIds: input.toppingIds,
        recipes: recipes,
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

  Future<ProductIngredient> createIngredient({
    required String name,
    required int itemType,
    required String unit,
    required int capacity,
  }) async {
    _ensureAllowed(
      _access.canCreateProduct,
      'Bạn chưa có quyền thêm nguyên liệu',
    );

    final cleanName = name.trim();
    final cleanUnit = unit.trim();
    if (cleanName.isEmpty) {
      throw Exception('Vui lòng nhập tên nguyên liệu');
    }
    if (cleanUnit.isEmpty) {
      throw Exception('Vui lòng nhập đơn vị nguyên liệu');
    }
    if (itemType != 1 && itemType != 2) {
      throw Exception('Vui lòng chọn loại nguyên liệu hợp lệ');
    }
    if (capacity < 0) {
      throw Exception('Vui lòng nhập dung lượng hợp lệ');
    }

    final ingredient = await ref.read(createProductIngredientUseCaseProvider)(
      storeId: _access.storeId,
      name: cleanName,
      itemType: itemType,
      unit: cleanUnit,
      capacity: capacity,
    );
    state = state.copyWith(
      ingredients: [...state.ingredients, ingredient],
      clearError: true,
    );
    return ingredient;
  }

  Future<ProductIngredient> updateIngredient({
    required int ingredientId,
    required String name,
    required int itemType,
    required String unit,
    required int capacity,
  }) async {
    _ensureAllowed(
      _access.canUpdateProduct,
      'Bạn chưa có quyền cập nhật nguyên liệu',
    );

    final cleanName = name.trim();
    final cleanUnit = unit.trim();
    if (cleanName.isEmpty) {
      throw Exception('Vui lòng nhập tên nguyên liệu');
    }
    if (cleanUnit.isEmpty) {
      throw Exception('Vui lòng nhập đơn vị nguyên liệu');
    }
    if (itemType != 1 && itemType != 2) {
      throw Exception('Vui lòng chọn loại nguyên liệu hợp lệ');
    }
    if (capacity < 0) {
      throw Exception('Vui lòng nhập dung lượng hợp lệ');
    }

    final ingredient = await ref.read(updateProductIngredientUseCaseProvider)(
      ingredientId: ingredientId,
      name: cleanName,
      itemType: itemType,
      unit: cleanUnit,
      capacity: capacity,
    );
    state = state.copyWith(
      ingredients: [
        for (final item in state.ingredients)
          if (item.id == ingredientId) ingredient else item,
      ],
      clearError: true,
    );
    return ingredient;
  }

  Future<void> deleteIngredient(int ingredientId) async {
    _ensureAllowed(
      _access.canDeleteProduct,
      'Bạn chưa có quyền xóa nguyên liệu',
    );

    await ref.read(deleteProductIngredientUseCaseProvider)(ingredientId);
    state = state.copyWith(
      ingredients: state.ingredients
          .where((ingredient) => ingredient.id != ingredientId)
          .toList(),
      clearError: true,
    );
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

    return _validatedStrictVariants(cleanVariants);
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

      if (variant.costPrice < 0) {
        throw Exception('Vui lòng nhập giá vốn tùy chọn hợp lệ');
      }

      cleanVariants.add(
        ProductVariantDraft(
          name: cleanName,
          price: variant.price,
          costPrice: variant.costPrice,
          isDefault: variant.isDefault,
        ),
      );
    }

    return cleanVariants;
  }

  int _resolvePrice(int? basePrice, List<ProductVariantDraft>? variants) {
    if (variants != null && variants.isNotEmpty) {
      return 0;
    }

    if (basePrice != null && basePrice > 0) {
      return basePrice;
    }

    throw Exception('Vui lòng nhập giá cơ bản');
  }

  int _resolveCostPrice(int? costPrice, List<ProductVariantDraft>? variants) {
    if (variants != null && variants.isNotEmpty) {
      return 0;
    }

    if (costPrice != null && costPrice >= 0) {
      return costPrice;
    }

    throw Exception('Vui lòng nhập giá vốn');
  }

  List<ProductRecipeDraft> _validatedRecipes(List<ProductRecipeDraft> recipes) {
    final cleanRecipes = <ProductRecipeDraft>[];
    final ingredientIds = <int>{};

    for (final recipe in recipes) {
      if (recipe.ingredientId <= 0) {
        throw Exception('Vui lòng chọn nguyên liệu hợp lệ');
      }

      if (!ingredientIds.add(recipe.ingredientId)) {
        throw Exception('Một nguyên liệu chỉ được chọn một lần');
      }

      if (recipe.quantity < 0 || recipe.capacity < 0) {
        throw Exception('Vui lòng nhập định mức nguyên liệu hợp lệ');
      }

      cleanRecipes.add(recipe);
    }

    return cleanRecipes;
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
