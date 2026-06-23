import '../entities/product_recipe_draft.dart';
import '../repositories/product_management_repository.dart';

class LoadProductRecipesUseCase {
  final ProductManagementRepository _repository;

  const LoadProductRecipesUseCase(this._repository);

  Future<List<ProductRecipeDraft>> call(int productId) =>
      _repository.loadProductRecipes(productId);
}
