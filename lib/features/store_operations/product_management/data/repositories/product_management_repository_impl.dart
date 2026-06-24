import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/entities/inventory_deduction_mode.dart';
import '../../domain/entities/inventory_item_settings.dart';
import '../../domain/entities/product_ingredient.dart';
import '../../domain/entities/product_image_upload.dart';
import '../../domain/entities/product_management_detail.dart';
import '../../domain/entities/product_recipe_draft.dart';
import '../../domain/entities/product_topping.dart';
import '../../domain/entities/product_type.dart';
import '../../domain/entities/product_variant_draft.dart';
import '../../domain/repositories/product_management_repository.dart';
import '../datasources/product_management_remote_data_source.dart';
import '../models/product_management_request_models.dart';

class ProductManagementRepositoryImpl implements ProductManagementRepository {
  final ProductManagementRemoteDataSource _remoteDataSource;

  const ProductManagementRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ProductCategory>> loadCategories(int storeId) async {
    final categories = await _remoteDataSource.getCategoriesByStore(storeId);
    return categories
        .map((category) => category.toEntity())
        .where((category) => !category.isDeleted)
        .toList();
  }

  @override
  Future<List<ProductTopping>> loadToppings(int storeId) async {
    final toppings = await _remoteDataSource.getToppingsByStore(storeId);
    return toppings
        .map((topping) => topping.toEntity())
        .where((topping) => !topping.isDeleted)
        .toList();
  }

  @override
  Future<List<ProductIngredient>> loadIngredients(int storeId) async {
    final ingredients = await _remoteDataSource.getIngredientsByStore(storeId);
    return ingredients
        .map((ingredient) => ingredient.toEntity())
        .where((ingredient) => ingredient.isActive && !ingredient.isDeleted)
        .toList();
  }

  @override
  Future<List<IngredientInventorySettings>> loadIngredientInventorySettings(
    int storeId,
  ) async {
    final items = await _remoteDataSource.getIngredientInventorySettings(
      storeId,
    );
    return items.map((item) => item.toEntity()).toList();
  }

  @override
  Future<ProductIngredient> createIngredient({
    required int storeId,
    required String name,
    required int itemType,
    required String unit,
    required int capacity,
  }) async {
    final ingredient = await _remoteDataSource.createIngredient(
      CreateProductIngredientRequestModel(
        storeId: storeId,
        name: name,
        itemType: itemType,
        unit: unit,
        capacity: capacity,
      ),
    );
    return ingredient.toEntity();
  }

  @override
  Future<ProductIngredient> updateIngredient({
    required int ingredientId,
    required String name,
    required int itemType,
    required String unit,
    required int capacity,
  }) async {
    final ingredient = await _remoteDataSource.updateIngredient(
      ingredientId: ingredientId,
      request: UpdateProductIngredientRequestModel(
        name: name,
        itemType: itemType,
        unit: unit,
        capacity: capacity,
      ),
    );
    return ingredient.toEntity();
  }

  @override
  Future<void> deleteIngredient(int ingredientId) {
    return _remoteDataSource.deleteIngredient(ingredientId);
  }

  @override
  Future<void> updateIngredientInventorySettings({
    required int ingredientId,
    required double minimumStock,
    required bool isTrackInventory,
  }) {
    return _remoteDataSource.updateIngredientInventorySettings(
      ingredientId: ingredientId,
      request: UpdateIngredientInventorySettingsRequestModel(
        minimumStock: minimumStock,
        isTrackInventory: isTrackInventory,
      ),
    );
  }

  @override
  Future<ProductTopping> createTopping({
    required int storeId,
    required String name,
    required int price,
  }) async {
    final topping = await _remoteDataSource.createTopping(
      CreateProductToppingRequestModel(
        storeId: storeId,
        name: name,
        price: price,
      ),
    );
    return topping.toEntity();
  }

  @override
  Future<ProductTopping> updateTopping({
    required int toppingId,
    required String name,
    required int price,
  }) async {
    final topping = await _remoteDataSource.updateTopping(
      toppingId: toppingId,
      request: UpdateProductToppingRequestModel(name: name, price: price),
    );
    return topping.toEntity();
  }

  @override
  Future<void> deleteTopping(int toppingId) {
    return _remoteDataSource.deleteTopping(toppingId);
  }

  @override
  Future<ProductCategory> createCategory({
    required int storeId,
    required String name,
  }) async {
    final category = await _remoteDataSource.createCategory(
      CreateProductCategoryRequestModel(storeId: storeId, name: name),
    );
    return category.toEntity();
  }

  @override
  Future<ProductCategory> updateCategory({
    required int categoryId,
    required String name,
  }) async {
    final category = await _remoteDataSource.updateCategory(
      categoryId: categoryId,
      request: UpdateProductCategoryRequestModel(name: name),
    );
    return category.toEntity();
  }

  @override
  Future<void> deleteCategory(int categoryId) {
    return _remoteDataSource.deleteCategory(categoryId);
  }

  @override
  Future<List<Product>> loadProducts(int storeId) async {
    final products = await _remoteDataSource.getProductsByStore(storeId);
    return products
        .map((product) => product.toEntity())
        .where((product) => !product.isDeleted)
        .toList();
  }

  @override
  Future<List<ProductInventorySettings>> loadProductInventorySettings(
    int storeId,
  ) async {
    final items = await _remoteDataSource.getProductInventorySettings(storeId);
    return items.map((item) => item.toEntity()).toList();
  }

  @override
  Future<Product> loadProductDetail(int productId) async {
    final product = await _remoteDataSource.getProductById(productId);
    return product.toEntity();
  }

  @override
  Future<ProductManagementDetail> loadProductManagementDetail(
    int productId,
  ) async {
    final detail = await _remoteDataSource.getProductManagementDetail(
      productId,
    );
    return detail.toEntity();
  }

  @override
  Future<List<ProductRecipeDraft>> loadProductRecipes(int productId) {
    return _remoteDataSource.getProductRecipes(productId);
  }

  @override
  Future<String> uploadProductImage({
    required int storeId,
    required ProductImageUpload image,
  }) {
    return _remoteDataSource.uploadProductImage(storeId: storeId, image: image);
  }

  @override
  Future<Product> createProduct({
    required int storeId,
    required int categoryId,
    required String name,
    required String imageUrl,
    required String description,
    required int preparationTime,
    required int price,
    required int costPrice,
    required ProductType type,
    List<ProductVariantDraft>? variants,
    required List<int> toppingIds,
    required List<ProductRecipeDraft> recipes,
  }) async {
    final product = await _remoteDataSource.createProduct(
      CreateProductRequestModel(
        storeId: storeId,
        categoryId: categoryId,
        name: name,
        imageUrl: imageUrl,
        description: description,
        preparationTime: preparationTime,
        price: price,
        costPrice: costPrice,
        type: type,
        variants: variants,
        toppingIds: toppingIds,
        recipes: recipes,
      ),
    );
    return product.toEntity();
  }

  @override
  Future<ProductInventorySettings> updateProductInventorySettings({
    required int productId,
    required double minimumStock,
    required bool isTrackInventory,
    required InventoryDeductionMode inventoryDeductionMode,
  }) {
    return _remoteDataSource
        .updateProductInventorySettings(
          productId: productId,
          request: UpdateProductInventorySettingsRequestModel(
            minimumStock: minimumStock,
            isTrackInventory: isTrackInventory,
            inventoryDeductionMode: inventoryDeductionMode,
          ),
        )
        .then((settings) => settings.toEntity());
  }

  @override
  Future<void> replaceProductRecipe({
    required int productId,
    required List<ProductRecipeDraft> recipes,
  }) {
    return _remoteDataSource.replaceProductRecipe(
      productId: productId,
      request: ReplaceProductRecipeRequestModel(recipes),
    );
  }

  @override
  Future<Product> updateProduct({
    required int productId,
    required int storeId,
    required int categoryId,
    required String name,
    required String imageUrl,
    required String description,
    required int preparationTime,
    required int price,
    required int costPrice,
    required ProductType type,
    List<ProductVariantDraft>? variants,
    required List<int> toppingIds,
  }) async {
    final product = await _remoteDataSource.updateProduct(
      productId: productId,
      request: UpdateProductRequestModel(
        categoryId: categoryId,
        name: name,
        imageUrl: imageUrl,
        description: description,
        preparationTime: preparationTime,
        price: price,
        costPrice: costPrice,
        type: type,
        variants: variants,
        toppingIds: toppingIds,
      ),
    );
    return product.toEntity();
  }

  @override
  Future<ProductManagementDetail> saveProductManagementDetail({
    required int productId,
    required int storeId,
    required int categoryId,
    required String name,
    required String existingImageUrl,
    ProductImageUpload? imageUpload,
    required String description,
    required int preparationTime,
    required int price,
    required int costPrice,
    required ProductType type,
    required List<ProductVariantDraft> variants,
    required List<ProductRecipeDraft> recipes,
    required List<int> toppingIds,
    required double minimumStock,
    required bool isTrackInventory,
    required InventoryDeductionMode inventoryDeductionMode,
  }) async {
    final imageUrl = imageUpload == null
        ? existingImageUrl
        : await _remoteDataSource.uploadProductImage(
            storeId: storeId,
            image: imageUpload,
          );
    final detail = await _remoteDataSource.updateProductManagementDetail(
      productId: productId,
      request: UpdateProductManagementDetailRequestModel(
        categoryId: categoryId,
        name: name,
        imageUrl: imageUrl,
        description: description,
        preparationTime: preparationTime,
        price: price,
        costPrice: costPrice,
        type: type,
        variants: variants,
        recipes: recipes,
        toppingIds: toppingIds,
        minimumStock: minimumStock,
        isTrackInventory: isTrackInventory,
        inventoryDeductionMode: inventoryDeductionMode,
      ),
    );
    return detail.toEntity();
  }

  @override
  Future<void> updateProductSellStatus({
    required int productId,
    required bool isSell,
  }) {
    return _remoteDataSource.updateProductSellStatus(
      productId: productId,
      request: UpdateProductSellStatusRequestModel(isSell: isSell),
    );
  }

  @override
  Future<void> deleteProduct(int productId) {
    return _remoteDataSource.deleteProduct(productId);
  }
}
