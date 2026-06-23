import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/product_management/data/models/product_management_request_models.dart';
import 'package:quan_oi/features/store_operations/product_management/data/models/product_model.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/inventory_deduction_mode.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_recipe_draft.dart';
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

  test('create product recipe payload sends legacy capacity as zero', () {
    const request = CreateProductRequestModel(
      storeId: 5,
      categoryId: 1,
      name: 'Trà đào',
      imageUrl: '',
      description: '',
      preparationTime: 5,
      price: 35000,
      costPrice: 0,
      type: ProductType.drink,
      toppingIds: [],
      recipes: [
        ProductRecipeDraft(ingredientId: 10, quantity: 15, capacity: 999),
      ],
    );

    final json = request.toJson();

    expect(json['recipes'], [
      {'ingredientId': 10, 'quantity': 15.0, 'capacity': 0},
    ]);
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

  test('maps active product inventory flags from product response', () {
    final product = ProductModel.fromJson({
      'id': 20,
      'storeId': 5,
      'categoryId': 1,
      'name': 'Coca Cola lon',
      'preparationTime': 0,
      'price': 12000,
      'costPrice': 10000,
      'type': 2,
      'isActive': true,
      'quantity': 2.5,
      'minimumStock': 6,
      'isTrackInventory': true,
      'inventoryDeductionMode': 'ProductOnly',
      'isLowStock': true,
      'isOutOfStock': false,
      'isDeleted': false,
    }).toEntity();

    expect(product.isActive, isTrue);
    expect(product.quantity, 2.5);
    expect(product.isLowStock, isTrue);
    expect(product.isOutOfStock, isFalse);
    expect(product.recipes, isEmpty);
  });
}
