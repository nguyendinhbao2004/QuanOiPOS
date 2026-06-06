import '../../domain/entities/product_type.dart';
import '../../domain/entities/product_variant_draft.dart';

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

class CreateProductRequestModel {
  final int storeId;
  final int categoryId;
  final String name;
  final String imageUrl;
  final String description;
  final int preparationTime;
  final int price;
  final ProductType type;
  final List<ProductVariantDraft>? variants;
  final List<int> toppingIds;

  const CreateProductRequestModel({
    required this.storeId,
    required this.categoryId,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.preparationTime,
    required this.price,
    required this.type,
    this.variants,
    required this.toppingIds,
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
      'type': type.value,
      'variants': variants
          ?.map(
            (variant) => {
              'name': variant.name,
              'price': variant.price,
              'isDefault': variant.isDefault,
            },
          )
          .toList(),
      'toppingIds': toppingIds,
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
