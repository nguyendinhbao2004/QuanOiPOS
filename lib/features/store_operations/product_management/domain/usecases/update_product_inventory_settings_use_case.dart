import '../entities/inventory_deduction_mode.dart';
import '../repositories/product_management_repository.dart';

class UpdateProductInventorySettingsUseCase {
  final ProductManagementRepository _repository;

  const UpdateProductInventorySettingsUseCase(this._repository);

  Future<void> call({
    required int productId,
    required double minimumStock,
    required bool isTrackInventory,
    required InventoryDeductionMode inventoryDeductionMode,
  }) {
    return _repository.updateProductInventorySettings(
      productId: productId,
      minimumStock: minimumStock,
      isTrackInventory: isTrackInventory,
      inventoryDeductionMode: inventoryDeductionMode,
    );
  }
}
