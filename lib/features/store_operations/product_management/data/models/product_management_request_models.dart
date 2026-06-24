import '../../domain/entities/product_type.dart';
import '../../domain/entities/product_variant_draft.dart';
import '../../domain/entities/product_recipe_draft.dart';
import '../../domain/entities/inventory_deduction_mode.dart';

class CreateProductCategoryRequestModel {
  final int storeId;
  final String name;

  const CreateProductCategoryRequestModel({
    required this.storeId,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {'storeId': storeId, 'name': name};
  }
}

class UpdateProductCategoryRequestModel {
  final String name;

  const UpdateProductCategoryRequestModel({required this.name});

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

class CreateProductToppingRequestModel {
  final int storeId;
  final String name;
  final int price;

  const CreateProductToppingRequestModel({
    required this.storeId,
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {'storeId': storeId, 'name': name, 'price': price};
  }
}

class UpdateProductToppingRequestModel {
  final String name;
  final int price;

  const UpdateProductToppingRequestModel({
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'price': price};
  }
}

class CreateProductIngredientRequestModel {
  final int storeId;
  final String name;
  final int itemType;
  final String unit;
  final int capacity;

  const CreateProductIngredientRequestModel({
    required this.storeId,
    required this.name,
    required this.itemType,
    required this.unit,
    required this.capacity,
  });

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'name': name,
      'itemType': itemType,
      'unit': unit,
      'capacity': capacity,
    };
  }
}

class UpdateProductIngredientRequestModel {
  final String name;
  final int itemType;
  final String unit;
  final int capacity;

  const UpdateProductIngredientRequestModel({
    required this.name,
    required this.itemType,
    required this.unit,
    required this.capacity,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'itemType': itemType,
      'unit': unit,
      'capacity': capacity,
    };
  }
}

class CreateProductRequestModel {
  final int storeId;
  final int categoryId;
  final String name;
  final String imageUrl;
  final String description;
  final int preparationTime;
  final int price;
  final int costPrice;
  final ProductType type;
  final List<ProductVariantDraft>? variants;
  final List<int> toppingIds;
  final List<ProductRecipeDraft> recipes;

  const CreateProductRequestModel({
    required this.storeId,
    required this.categoryId,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.preparationTime,
    required this.price,
    required this.costPrice,
    required this.type,
    this.variants,
    required this.toppingIds,
    this.recipes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'categoryId': categoryId,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'preparationTime': preparationTime,
      'price': price,
      'costPrice': costPrice,
      'type': type.value,
      'variants': variants
          ?.map(
            (variant) => {
              'name': variant.name,
              'price': variant.price,
              'costPrice': variant.costPrice,
              'isDefault': variant.isDefault,
            },
          )
          .toList(),
      'toppingIds': toppingIds,
      'recipes': recipes
          .map(
            (recipe) => {
              'ingredientId': recipe.ingredientId,
              'quantity': recipe.quantity,
              'capacity': 0,
            },
          )
          .toList(),
    };
  }
}

class UpdateProductRequestModel {
  final int categoryId;
  final String name;
  final String imageUrl;
  final String description;
  final int preparationTime;
  final int price;
  final int costPrice;
  final ProductType type;
  final List<ProductVariantDraft>? variants;
  final List<int> toppingIds;

  const UpdateProductRequestModel({
    required this.categoryId,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.preparationTime,
    required this.price,
    required this.costPrice,
    required this.type,
    this.variants,
    required this.toppingIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'preparationTime': preparationTime,
      'price': price,
      'costPrice': costPrice,
      'type': type.value,
      'variants': variants
          ?.map(
            (variant) => {
              'name': variant.name,
              'price': variant.price,
              'costPrice': variant.costPrice,
              'isDefault': variant.isDefault,
            },
          )
          .toList(),
      'toppingIds': toppingIds,
    };
  }
}

class UpdateProductManagementDetailRequestModel {
  final int categoryId;
  final String name;
  final String? imageUrl;
  final String description;
  final int preparationTime;
  final int price;
  final int costPrice;
  final ProductType type;
  final List<ProductVariantDraft> variants;
  final List<ProductRecipeDraft> recipes;
  final List<int> toppingIds;
  final double minimumStock;
  final bool isTrackInventory;
  final InventoryDeductionMode inventoryDeductionMode;

  const UpdateProductManagementDetailRequestModel({
    required this.categoryId,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.preparationTime,
    required this.price,
    required this.costPrice,
    required this.type,
    required this.variants,
    required this.recipes,
    required this.toppingIds,
    required this.minimumStock,
    required this.isTrackInventory,
    required this.inventoryDeductionMode,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'preparationTime': preparationTime,
      'price': price,
      'costPrice': costPrice,
      'type': type.value,
      'variants': variants.map(_variantToJson).toList(),
      'recipes': recipes.map(_recipeToJson).toList(),
      'toppingIds': toppingIds,
      'inventorySettings': {
        'minimumStock': minimumStock,
        'isTrackInventory': isTrackInventory,
        'inventoryDeductionMode': inventoryDeductionMode.apiValue,
      },
    };
  }

  Map<String, dynamic> _variantToJson(ProductVariantDraft variant) {
    return {
      'id': variant.id,
      'name': variant.name,
      'price': variant.price,
      'costPrice': variant.costPrice,
      'isDefault': variant.isDefault,
      'minimumStock': variant.minimumStock,
      'isTrackInventory': variant.isTrackInventory,
      'recipeAdjustments': variant.recipeAdjustments
          .where((adjustment) => adjustment.quantityDelta != 0)
          .map(
            (adjustment) => {
              'id': adjustment.id,
              'ingredientId': adjustment.ingredientId,
              'quantityDelta': adjustment.quantityDelta,
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic> _recipeToJson(ProductRecipeDraft recipe) {
    return {
      'ingredientId': recipe.ingredientId,
      'quantity': recipe.quantity,
      'capacity': recipe.capacity,
    };
  }
}

class UpdateIngredientInventorySettingsRequestModel {
  final double minimumStock;
  final bool isTrackInventory;

  const UpdateIngredientInventorySettingsRequestModel({
    required this.minimumStock,
    required this.isTrackInventory,
  });

  Map<String, dynamic> toJson() {
    return {'minimumStock': minimumStock, 'isTrackInventory': isTrackInventory};
  }
}

class UpdateProductInventorySettingsRequestModel {
  final double minimumStock;
  final bool isTrackInventory;
  final InventoryDeductionMode inventoryDeductionMode;

  const UpdateProductInventorySettingsRequestModel({
    required this.minimumStock,
    required this.isTrackInventory,
    required this.inventoryDeductionMode,
  });

  Map<String, dynamic> toJson() {
    return {
      'minimumStock': minimumStock,
      'isTrackInventory': isTrackInventory,
      'inventoryDeductionMode': inventoryDeductionMode.apiValue,
    };
  }
}

class ReplaceProductRecipeRequestModel {
  final List<ProductRecipeDraft> recipes;

  const ReplaceProductRecipeRequestModel(this.recipes);

  List<Map<String, dynamic>> toJson() {
    return recipes
        .map(
          (recipe) => {
            'ingredientId': recipe.ingredientId,
            'quantity': recipe.quantity,
          },
        )
        .toList();
  }
}

class UpdateProductSellStatusRequestModel {
  final bool isSell;

  const UpdateProductSellStatusRequestModel({required this.isSell});

  Map<String, dynamic> toJson() {
    return {'isSell': isSell};
  }
}
