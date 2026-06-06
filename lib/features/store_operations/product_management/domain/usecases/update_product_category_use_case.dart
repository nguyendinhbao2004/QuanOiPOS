import '../entities/product_category.dart';
import '../repositories/product_management_repository.dart';

class UpdateProductCategoryUseCase {
  final ProductManagementRepository _repository;

  const UpdateProductCategoryUseCase(this._repository);

  Future<ProductCategory> call({
    required int categoryId,
    required String name,
  }) {
    return _repository.updateCategory(categoryId: categoryId, name: name);
  }
}
