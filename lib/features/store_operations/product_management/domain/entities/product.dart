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
  final bool isActive;
  final bool isLowStock;
  final bool isOutOfStock;
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
    bool? isActive,
    @Deprecated('Use isActive instead.') bool? isSell,
    this.isLowStock = false,
    this.isOutOfStock = false,
    this.createdAt,
    this.updatedAt,
    required this.isDeleted,
  }) : isActive = isActive ?? isSell ?? true;

  @Deprecated('Use isActive instead.')
  bool get isSell => isActive;

  Product copyWith({
    double? minimumStock,
    bool? isTrackInventory,
    InventoryDeductionMode? inventoryDeductionMode,
    double? quantity,
    double? averageUnitCost,
    double? lastImportUnitCost,
    bool? isActive,
    bool? isLowStock,
    bool? isOutOfStock,
    List<ProductRecipeDraft>? recipes,
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
      quantity: quantity ?? this.quantity,
      minimumStock: minimumStock ?? this.minimumStock,
      averageUnitCost: averageUnitCost ?? this.averageUnitCost,
      lastImportUnitCost: lastImportUnitCost ?? this.lastImportUnitCost,
      isTrackInventory: isTrackInventory ?? this.isTrackInventory,
      inventoryDeductionMode:
          inventoryDeductionMode ?? this.inventoryDeductionMode,
      type: type,
      variants: variants,
      toppings: toppings,
      recipes: recipes ?? this.recipes,
      isActive: isActive,
      isLowStock: isLowStock ?? this.isLowStock,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
    );
  }
}
