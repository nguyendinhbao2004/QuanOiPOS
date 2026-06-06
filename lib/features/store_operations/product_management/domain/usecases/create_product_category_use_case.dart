import '../entities/product_category.dart';
import '../repositories/product_management_repository.dart';

class CreateProductCategoryUseCase {
  final ProductManagementRepository _repository;

  const CreateProductCategoryUseCase(this._repository);

  Future<ProductCategory> call({required int storeId, required String name}) {
    return _repository.createCategory(storeId: storeId, name: name);
  }
}
