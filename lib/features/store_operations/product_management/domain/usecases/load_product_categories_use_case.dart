import '../entities/product_category.dart';
import '../repositories/product_management_repository.dart';

class LoadProductCategoriesUseCase {
  final ProductManagementRepository _repository;

  const LoadProductCategoriesUseCase(this._repository);

  Future<List<ProductCategory>> call(int storeId) {
    return _repository.loadCategories(storeId);
  }
}
