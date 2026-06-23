import '../entities/inventory_item_settings.dart';
import '../repositories/product_management_repository.dart';

class LoadProductInventorySettingsUseCase {
  final ProductManagementRepository _repository;

  const LoadProductInventorySettingsUseCase(this._repository);

  Future<List<ProductInventorySettings>> call(int storeId) {
    return _repository.loadProductInventorySettings(storeId);
  }
}
