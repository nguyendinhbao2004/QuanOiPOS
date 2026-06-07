import '../repositories/product_management_repository.dart';

class DeleteProductToppingUseCase {
  final ProductManagementRepository _repository;

  const DeleteProductToppingUseCase(this._repository);

  Future<void> call(int toppingId) {
    return _repository.deleteTopping(toppingId);
  }
}
