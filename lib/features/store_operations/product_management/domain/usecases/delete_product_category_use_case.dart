import '../repositories/product_management_repository.dart';

class DeleteProductCategoryUseCase {
  final ProductManagementRepository _repository;

  const DeleteProductCategoryUseCase(this._repository);

  Future<void> call(int categoryId) {
    return _repository.deleteCategory(categoryId);
  }
}
