import '../entities/product_ingredient.dart';
import '../repositories/product_management_repository.dart';

class LoadProductIngredientsUseCase {
  final ProductManagementRepository _repository;

  const LoadProductIngredientsUseCase(this._repository);

  Future<List<ProductIngredient>> call(int storeId) {
    return _repository.loadIngredients(storeId);
  }
}
