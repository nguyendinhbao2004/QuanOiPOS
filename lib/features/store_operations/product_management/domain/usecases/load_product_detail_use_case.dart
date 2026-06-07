import '../entities/product.dart';
import '../repositories/product_management_repository.dart';

class LoadProductDetailUseCase {
  final ProductManagementRepository _repository;

  const LoadProductDetailUseCase(this._repository);

  Future<Product> call(int productId) {
    return _repository.loadProductDetail(productId);
  }
}
