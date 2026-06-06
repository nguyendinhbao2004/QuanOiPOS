import '../entities/product.dart';
import '../repositories/product_management_repository.dart';

class LoadProductsUseCase {
  final ProductManagementRepository _repository;

  const LoadProductsUseCase(this._repository);

  Future<List<Product>> call(int storeId) {
    return _repository.loadProducts(storeId);
  }
}
