import '../entities/product_management_detail.dart';
import '../repositories/product_management_repository.dart';

class LoadProductManagementDetailUseCase {
  final ProductManagementRepository _repository;

  const LoadProductManagementDetailUseCase(this._repository);

  Future<ProductManagementDetail> call(int productId) {
    return _repository.loadProductManagementDetail(productId);
  }
}
