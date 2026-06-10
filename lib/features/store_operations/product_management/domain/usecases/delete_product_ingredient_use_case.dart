import '../repositories/product_management_repository.dart';

class DeleteProductIngredientUseCase {
  final ProductManagementRepository _repository;

  const DeleteProductIngredientUseCase(this._repository);

  Future<void> call(int ingredientId) {
    return _repository.deleteIngredient(ingredientId);
  }
}
