import '../repositories/product_management_repository.dart';

class DeleteProductUseCase {
  final ProductManagementRepository _repository;

  const DeleteProductUseCase(this._repository);

  Future<void> call(int productId) {
    return _repository.deleteProduct(productId);
  }
}
