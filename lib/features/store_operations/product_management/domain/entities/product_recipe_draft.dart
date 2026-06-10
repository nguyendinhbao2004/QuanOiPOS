import 'product_ingredient.dart';

class ProductRecipeDraft {
  final int? id;
  final int ingredientId;
  final ProductIngredient? ingredient;
  final int quantity;
  final int capacity;

  const ProductRecipeDraft({
    this.id,
    required this.ingredientId,
    this.ingredient,
    required this.quantity,
    required this.capacity,
  });
}
