import '../entities/product_ingredient.dart';
import '../repositories/product_management_repository.dart';

class UpdateProductIngredientUseCase {
  final ProductManagementRepository _repository;

  const UpdateProductIngredientUseCase(this._repository);

  Future<ProductIngredient> call({
    required int ingredientId,
    required String name,
    required int itemType,
    required String unit,
    required int capacity,
  }) {
    return _repository.updateIngredient(
      ingredientId: ingredientId,
      name: name,
      itemType: itemType,
      unit: unit,
      capacity: capacity,
    );
  }
}
