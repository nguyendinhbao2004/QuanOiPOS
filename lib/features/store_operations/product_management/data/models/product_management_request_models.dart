import '../../domain/entities/product_type.dart';
import '../../domain/entities/product_variant_draft.dart';
import '../../domain/entities/product_recipe_draft.dart';

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
              'capacity': recipe.capacity,
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
  final List<ProductRecipeDraft> recipes;

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
    this.recipes = const [],
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
      'recipes': recipes
          .map(
            (recipe) => {
              'ingredientId': recipe.ingredientId,
              'quantity': recipe.quantity,
              'capacity': recipe.capacity,
            },
          )
          .toList(),
    };
  }
}

class UpdateProductSellStatusRequestModel {
  final bool isSell;

  const UpdateProductSellStatusRequestModel({required this.isSell});

  Map<String, dynamic> toJson() {
    return {'isSell': isSell};
  }
}
