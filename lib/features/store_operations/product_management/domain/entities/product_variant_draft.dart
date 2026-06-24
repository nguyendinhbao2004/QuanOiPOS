import 'product_variant_recipe_adjustment.dart';

class ProductVariantDraft {
  final int? id;
  final String name;
  final int price;
  final int costPrice;
  final bool isDefault;
  final bool isActive;
  final double quantity;
  final double minimumStock;
  final double averageUnitCost;
  final double lastImportUnitCost;
  final bool isTrackInventory;
  final bool isLowStock;
  final bool isOutOfStock;
  final List<ProductVariantRecipeAdjustment> recipeAdjustments;

  const ProductVariantDraft({
    this.id,
    required this.name,
    required this.price,
    this.costPrice = 0,
    required this.isDefault,
    this.isActive = true,
    this.quantity = 0,
    this.minimumStock = 0,
    this.averageUnitCost = 0,
    this.lastImportUnitCost = 0,
    this.isTrackInventory = false,
    this.isLowStock = false,
    this.isOutOfStock = false,
    this.recipeAdjustments = const [],
  });
}
