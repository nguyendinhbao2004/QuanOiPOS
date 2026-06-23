import 'product_type.dart';
import 'product_topping.dart';
import 'product_variant_draft.dart';
import 'product_recipe_draft.dart';
import 'inventory_deduction_mode.dart';

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
  final double quantity;
  final double minimumStock;
  final double averageUnitCost;
  final double lastImportUnitCost;
  final bool isTrackInventory;
  final InventoryDeductionMode inventoryDeductionMode;
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
    this.quantity = 0,
    this.minimumStock = 0,
    this.averageUnitCost = 0,
    this.lastImportUnitCost = 0,
    this.isTrackInventory = false,
    this.inventoryDeductionMode = InventoryDeductionMode.recipeOnly,
    required this.type,
    this.variants = const [],
    this.toppings = const [],
    this.recipes = const [],
    required this.isSell,
    this.createdAt,
    this.updatedAt,
    required this.isDeleted,
  });

  Product copyWith({
    double? minimumStock,
    bool? isTrackInventory,
    InventoryDeductionMode? inventoryDeductionMode,
  }) {
    return Product(
      id: id,
      storeId: storeId,
      categoryId: categoryId,
      categoryName: categoryName,
      name: name,
      imageUrl: imageUrl,
      description: description,
      preparationTime: preparationTime,
      price: price,
      costPrice: costPrice,
      quantity: quantity,
      minimumStock: minimumStock ?? this.minimumStock,
      averageUnitCost: averageUnitCost,
      lastImportUnitCost: lastImportUnitCost,
      isTrackInventory: isTrackInventory ?? this.isTrackInventory,
      inventoryDeductionMode:
          inventoryDeductionMode ?? this.inventoryDeductionMode,
      type: type,
      variants: variants,
      toppings: toppings,
      recipes: recipes,
      isSell: isSell,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
    );
  }
}
