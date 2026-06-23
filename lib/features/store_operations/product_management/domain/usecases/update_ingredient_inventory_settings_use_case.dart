import '../repositories/product_management_repository.dart';

class UpdateIngredientInventorySettingsUseCase {
  final ProductManagementRepository _repository;

  const UpdateIngredientInventorySettingsUseCase(this._repository);

  Future<void> call({
    required int ingredientId,
    required double minimumStock,
    required bool isTrackInventory,
  }) {
    return _repository.updateIngredientInventorySettings(
      ingredientId: ingredientId,
      minimumStock: minimumStock,
      isTrackInventory: isTrackInventory,
    );
  }
}
