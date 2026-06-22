import '../entities/product.dart';
import '../entities/product_image_upload.dart';
import '../entities/product_recipe_draft.dart';
import '../entities/product_type.dart';
import '../entities/product_variant_draft.dart';
import '../repositories/product_management_repository.dart';

class CreateProductUseCase {
  final ProductManagementRepository _repository;

  const CreateProductUseCase(this._repository);

  Future<Product> call({
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
  }) {
    return _repository.createProduct(
      storeId: storeId,
      categoryId: categoryId,
      name: name,
      imageUpload: imageUpload,
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
