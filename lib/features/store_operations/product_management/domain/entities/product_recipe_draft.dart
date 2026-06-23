import 'product_ingredient.dart';

class ProductRecipeDraft {
  final int? id;
  final int ingredientId;
  final ProductIngredient? ingredient;
  final double quantity;
  final double capacity;

  const ProductRecipeDraft({
    this.id,
    required this.ingredientId,
    this.ingredient,
    required this.quantity,
    required this.capacity,
  });
}
