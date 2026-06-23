import '../entities/inventory_item_settings.dart';
import '../repositories/product_management_repository.dart';

class LoadIngredientInventorySettingsUseCase {
  final ProductManagementRepository _repository;

  const LoadIngredientInventorySettingsUseCase(this._repository);

  Future<List<IngredientInventorySettings>> call(int storeId) {
    return _repository.loadIngredientInventorySettings(storeId);
  }
}
