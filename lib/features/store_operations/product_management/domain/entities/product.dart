import 'product_type.dart';
import 'product_topping.dart';
import 'product_variant_draft.dart';
import 'product_recipe_draft.dart';

class Product {
  final int id;
  final int storeId;
  final int categoryId;
  final String categoryName;
  final String name;
  final String imageUrl;
  final String description;
  final int preparationTime;
  final int price;
  final int costPrice;
  final ProductType type;
  final List<ProductVariantDraft> variants;
  final List<ProductTopping> toppings;
  final List<ProductRecipeDraft> recipes;
  final bool isSell;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  const Product({
    required this.id,
    required this.storeId,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.preparationTime,
    required this.price,
    this.costPrice = 0,
    required this.type,
    this.variants = const [],
    this.toppings = const [],
    this.recipes = const [],
    required this.isSell,
    this.createdAt,
    this.updatedAt,
    required this.isDeleted,
  });
}
