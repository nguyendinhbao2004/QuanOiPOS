import '../entities/product.dart';
import '../entities/product_category.dart';
import '../entities/product_image_upload.dart';
import '../entities/product_ingredient.dart';
import '../entities/inventory_deduction_mode.dart';
import '../entities/inventory_item_settings.dart';
import '../entities/product_recipe_draft.dart';
import '../entities/product_topping.dart';
import '../entities/product_type.dart';
import '../entities/product_variant_draft.dart';

abstract class ProductManagementRepository {
  Future<List<ProductCategory>> loadCategories(int storeId);

  Future<List<ProductTopping>> loadToppings(int storeId);

  Future<List<ProductIngredient>> loadIngredients(int storeId);

  @Deprecated('Ingredient responses now contain inventory settings directly.')
  Future<List<IngredientInventorySettings>> loadIngredientInventorySettings(
    int storeId,
  );

  Future<ProductIngredient> createIngredient({
    required int storeId,
    required String name,
    required int itemType,
    required String unit,
    required int capacity,
  });

  Future<ProductIngredient> updateIngredient({
    required int ingredientId,
    required String name,
    required int itemType,
    required String unit,
    required int capacity,
  });

  Future<void> deleteIngredient(int ingredientId);

  Future<void> updateIngredientInventorySettings({
    required int ingredientId,
    required double minimumStock,
    required bool isTrackInventory,
  });

  Future<ProductTopping> createTopping({
    required int storeId,
    required String name,
    required int price,
  });

  Future<ProductTopping> updateTopping({
    required int toppingId,
    required String name,
    required int price,
  });

  Future<void> deleteTopping(int toppingId);

  Future<ProductCategory> createCategory({
    required int storeId,
    required String name,
  });

  Future<ProductCategory> updateCategory({
    required int categoryId,
    required String name,
  });

  Future<void> deleteCategory(int categoryId);

  Future<List<Product>> loadProducts(int storeId);

  @Deprecated('Product responses now contain inventory settings directly.')
  Future<List<ProductInventorySettings>> loadProductInventorySettings(
    int storeId,
  );

  Future<Product> loadProductDetail(int productId);

  Future<List<ProductRecipeDraft>> loadProductRecipes(int productId);

  Future<Product> createProduct({
    required int storeId,
    required int categoryId,
    required String name,
    ProductImageUpload? imageUpload,
    required String description,
    required int preparationTime,
    required int price,
    required int costPrice,
    required ProductType type,
    List<ProductVariantDraft>? variants,
    required List<int> toppingIds,
    required List<ProductRecipeDraft> recipes,
  });

  Future<ProductInventorySettings> updateProductInventorySettings({
    required int productId,
    required double minimumStock,
    required bool isTrackInventory,
    required InventoryDeductionMode inventoryDeductionMode,
  });

  Future<void> replaceProductRecipe({
    required int productId,
    required List<ProductRecipeDraft> recipes,
  });

  Future<Product> updateProduct({
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
    List<ProductVariantDraft>? variants,
    required List<int> toppingIds,
  });

  Future<void> updateProductSellStatus({
    required int productId,
    required bool isSell,
  });

  Future<void> deleteProduct(int productId);
}
