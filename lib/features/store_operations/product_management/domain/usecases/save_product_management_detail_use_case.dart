import '../entities/inventory_deduction_mode.dart';
import '../entities/product_image_upload.dart';
import '../entities/product_management_detail.dart';
import '../entities/product_recipe_draft.dart';
import '../entities/product_type.dart';
import '../entities/product_variant_draft.dart';
import '../repositories/product_management_repository.dart';

class SaveProductManagementDetailUseCase {
  final ProductManagementRepository _repository;

  const SaveProductManagementDetailUseCase(this._repository);

  Future<ProductManagementDetail> call({
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
  }) {
    return _repository.saveProductManagementDetail(
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
      recipes: recipes,
      toppingIds: toppingIds,
      minimumStock: minimumStock,
      isTrackInventory: isTrackInventory,
      inventoryDeductionMode: inventoryDeductionMode,
    );
  }
}
