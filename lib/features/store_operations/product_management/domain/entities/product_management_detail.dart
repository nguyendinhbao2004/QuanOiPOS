import 'product.dart';
import 'product_recipe_draft.dart';
import 'product_topping.dart';
import 'product_variant_draft.dart';
import 'product_variant_recipe_adjustment.dart';

class ProductManagementDetail {
  final Product product;
  final List<ProductVariantDraft> variants;
  final List<ProductRecipeDraft> recipes;
  final List<ProductVariantRecipeAdjustment> variantRecipeAdjustments;
  final List<ProductTopping> toppings;

  const ProductManagementDetail({
    required this.product,
    this.variants = const [],
    this.recipes = const [],
    this.variantRecipeAdjustments = const [],
    this.toppings = const [],
  });

  Product get editableProduct {
    return product.copyWith(
      variants: variants,
      toppings: toppings,
      recipes: recipes,
    );
  }
}
