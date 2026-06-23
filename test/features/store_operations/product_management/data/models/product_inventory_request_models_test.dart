import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/product_management/data/models/product_management_request_models.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/inventory_deduction_mode.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_type.dart';

void main() {
  test('catalog product payload excludes inventory settings', () {
    const request = CreateProductRequestModel(
      storeId: 5,
      categoryId: 1,
      name: 'Coca Cola lon',
      imageUrl: '',
      description: '',
      preparationTime: 0,
      price: 12000,
      costPrice: 10000,
      type: ProductType.food,
      toppingIds: [],
    );

    final json = request.toJson();

    expect(json.containsKey('minimumStock'), isFalse);
    expect(json.containsKey('isTrackInventory'), isFalse);
    expect(json.containsKey('inventoryDeductionMode'), isFalse);
  });

  test('inventory settings serialize API enum values', () {
    const productRequest = UpdateProductInventorySettingsRequestModel(
      minimumStock: 6,
      isTrackInventory: true,
      inventoryDeductionMode: InventoryDeductionMode.productOnly,
    );
    const ingredientRequest = UpdateIngredientInventorySettingsRequestModel(
      minimumStock: 1000,
      isTrackInventory: true,
    );

    expect(productRequest.toJson(), {
      'minimumStock': 6.0,
      'isTrackInventory': true,
      'inventoryDeductionMode': 'ProductOnly',
    });
    expect(ingredientRequest.toJson(), {
      'minimumStock': 1000.0,
      'isTrackInventory': true,
    });
  });
}
