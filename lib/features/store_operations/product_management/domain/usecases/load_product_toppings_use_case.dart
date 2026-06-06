import '../entities/product_topping.dart';
import '../repositories/product_management_repository.dart';

class LoadProductToppingsUseCase {
  final ProductManagementRepository _repository;

  const LoadProductToppingsUseCase(this._repository);

  Future<List<ProductTopping>> call(int storeId) {
    return _repository.loadToppings(storeId);
  }
}
