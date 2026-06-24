import 'product_ingredient.dart';

class ProductVariantRecipeAdjustment {
  final int? id;
  final int variantId;
  final int ingredientId;
  final ProductIngredient? ingredient;
  final String ingredientName;
  final String ingredientUnit;
  final double quantityDelta;
  final bool isActive;

  const ProductVariantRecipeAdjustment({
    this.id,
    this.variantId = 0,
    required this.ingredientId,
    this.ingredient,
    this.ingredientName = '',
    this.ingredientUnit = '',
    required this.quantityDelta,
    this.isActive = true,
  });
}
