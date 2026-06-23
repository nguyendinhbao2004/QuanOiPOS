import '../entities/product.dart';
import '../entities/product_image_upload.dart';
import '../entities/product_type.dart';
import '../entities/product_variant_draft.dart';
import '../repositories/product_management_repository.dart';

class UpdateProductUseCase {
  final ProductManagementRepository _repository;

  const UpdateProductUseCase(this._repository);

  Future<Product> call({
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
  }) {
    return _repository.updateProduct(
      productId: productId,
      storeId: storeId,
      categoryId: categoryId,
      name: name,
      existingImageUrl: existingImageUrl,
      imageUpload: imageUpload,
      description: description,
      preparationTime: preparationTime,
      price: price,
      costPrice: costPrice,
      type: type,
      variants: variants,
      toppingIds: toppingIds,
    );
  }
}
