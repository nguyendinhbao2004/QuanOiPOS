import '../entities/product_ingredient.dart';
import '../repositories/product_management_repository.dart';

class CreateProductIngredientUseCase {
  final ProductManagementRepository _repository;

  const CreateProductIngredientUseCase(this._repository);

  Future<ProductIngredient> call({
    required int storeId,
    required String name,
    required int itemType,
    required String unit,
    required int capacity,
  }) {
    return _repository.createIngredient(
      storeId: storeId,
      name: name,
      itemType: itemType,
      unit: unit,
      capacity: capacity,
    );
  }
}
