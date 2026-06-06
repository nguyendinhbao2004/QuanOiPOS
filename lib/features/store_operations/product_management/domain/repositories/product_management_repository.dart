import '../entities/product.dart';
import '../entities/product_category.dart';
import '../entities/product_topping.dart';
import '../entities/product_type.dart';
import '../entities/product_variant_draft.dart';

abstract class ProductManagementRepository {
  Future<List<ProductCategory>> loadCategories(int storeId);

  Future<List<ProductTopping>> loadToppings(int storeId);

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

  Future<Product> createProduct({
    required int storeId,
    required int categoryId,
    required String name,
    required String imageUrl,
    required String description,
    required int preparationTime,
    required int price,
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
