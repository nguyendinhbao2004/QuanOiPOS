import '../entities/product.dart';
import '../entities/product_recipe_draft.dart';
import '../entities/product_type.dart';
import '../entities/product_variant_draft.dart';
import '../repositories/product_management_repository.dart';

class UpdateProductUseCase {
  final ProductManagementRepository _repository;

  const UpdateProductUseCase(this._repository);

  Future<Product> call({
    required int productId,
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
  }) {
    return _repository.updateProduct(
      productId: productId,
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
    );
  }
}
