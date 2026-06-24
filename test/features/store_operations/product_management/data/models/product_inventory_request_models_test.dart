import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/product_management/data/models/product_management_request_models.dart';
import 'package:quan_oi/features/store_operations/product_management/data/models/product_management_detail_model.dart';
import 'package:quan_oi/features/store_operations/product_management/data/models/product_model.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/inventory_deduction_mode.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_recipe_draft.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_type.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_variant_draft.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_variant_recipe_adjustment.dart';

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

  test(
    'maps aggregate management detail including inactive rows and adjustments',
    () {
      final detail = ProductManagementDetailModel.fromJson({
        'product': {
          'id': 20,
          'storeId': 5,
          'categoryId': 1,
          'name': 'Trà đào',
          'preparationTime': 5,
          'price': 35000,
          'costPrice': 12000,
          'type': 1,
          'isActive': true,
          'inventoryDeductionMode': 'VariantOnly',
          'isDeleted': false,
        },
        'variants': [
          {
            'id': 201,
            'name': 'Size L',
            'price': 42000,
            'costPrice': 15000,
            'isDefault': true,
            'isActive': true,
            'quantity': 3,
            'minimumStock': 2,
            'averageUnitCost': 14000,
            'lastImportUnitCost': 14500,
            'isTrackInventory': true,
            'isLowStock': false,
            'isOutOfStock': false,
          },
          {
            'id': 202,
            'name': 'Size cũ',
            'price': 30000,
            'costPrice': 10000,
            'isDefault': false,
            'isActive': false,
          },
        ],
        'recipes': [
          {
            'id': 301,
            'productId': 20,
            'ingredientId': 11,
            'ingredientName': 'Trà',
            'ingredientUnit': 'gram',
            'quantity': 15,
            'capacity': 0,
            'isActive': true,
          },
        ],
        'variantRecipeAdjustments': [
          {
            'id': 401,
            'variantId': 201,
            'ingredientId': 11,
            'ingredientName': 'Trà',
            'ingredientUnit': 'gram',
            'quantityDelta': -2,
            'isActive': true,
          },
        ],
        'toppings': [
          {
            'id': 501,
            'toppingId': 9,
            'name': 'Thạch',
            'price': 5000,
            'isActive': true,
          },
        ],
      }).toEntity();

      expect(
        detail.product.inventoryDeductionMode,
        InventoryDeductionMode.variantOnly,
      );
      expect(detail.variants, hasLength(2));
      expect(detail.variants.first.recipeAdjustments.single.quantityDelta, -2);
      expect(detail.variants.last.isActive, isFalse);
      expect(detail.recipes.single.ingredient?.unit, 'gram');
      expect(detail.toppings.single.id, 9);
    },
  );

  test('aggregate save payload nests non-zero variant recipe adjustments', () {
    const request = UpdateProductManagementDetailRequestModel(
      categoryId: 1,
      name: 'Trà đào',
      imageUrl: '',
      description: '',
      preparationTime: 5,
      price: 35000,
      costPrice: 12000,
      type: ProductType.drink,
      variants: [
        ProductVariantDraft(
          id: 201,
          name: 'Size L',
          price: 42000,
          costPrice: 15000,
          isDefault: true,
          minimumStock: 2,
          isTrackInventory: true,
          recipeAdjustments: [
            ProductVariantRecipeAdjustment(
              id: 401,
              variantId: 201,
              ingredientId: 11,
              quantityDelta: -2,
            ),
            ProductVariantRecipeAdjustment(
              variantId: 201,
              ingredientId: 12,
              quantityDelta: 0,
            ),
          ],
        ),
      ],
      recipes: [
        ProductRecipeDraft(ingredientId: 11, quantity: 15, capacity: 0),
      ],
      toppingIds: [9],
      minimumStock: 6,
      isTrackInventory: true,
      inventoryDeductionMode: InventoryDeductionMode.variantOnly,
    );

    final json = request.toJson();

    expect(json['variants'], [
      {
        'id': 201,
        'name': 'Size L',
        'price': 42000,
        'costPrice': 15000,
        'isDefault': true,
        'minimumStock': 2.0,
        'isTrackInventory': true,
        'recipeAdjustments': [
          {'id': 401, 'ingredientId': 11, 'quantityDelta': -2.0},
        ],
      },
    ]);
    expect(json['inventorySettings'], {
      'minimumStock': 6.0,
      'isTrackInventory': true,
      'inventoryDeductionMode': 'VariantOnly',
    });
  });
}
