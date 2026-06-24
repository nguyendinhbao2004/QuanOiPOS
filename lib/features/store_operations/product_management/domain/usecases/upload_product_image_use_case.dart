import '../entities/product_image_upload.dart';
import '../repositories/product_management_repository.dart';

class UploadProductImageUseCase {
  final ProductManagementRepository _repository;

  const UploadProductImageUseCase(this._repository);

  Future<String> call({
    required int storeId,
    required ProductImageUpload image,
  }) {
    return _repository.uploadProductImage(storeId: storeId, image: image);
  }
}
