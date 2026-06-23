import '../entities/product_recipe_draft.dart';
import '../repositories/product_management_repository.dart';

class ReplaceProductRecipeUseCase {
  final ProductManagementRepository _repository;

  const ReplaceProductRecipeUseCase(this._repository);

  Future<void> call({
    required int productId,
    required List<ProductRecipeDraft> recipes,
  }) {
    return _repository.replaceProductRecipe(
      productId: productId,
      recipes: recipes,
    );
  }
}
