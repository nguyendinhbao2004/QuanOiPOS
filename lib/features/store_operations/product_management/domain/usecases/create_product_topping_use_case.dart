import '../entities/product_topping.dart';
import '../repositories/product_management_repository.dart';

class CreateProductToppingUseCase {
  final ProductManagementRepository _repository;

  const CreateProductToppingUseCase(this._repository);

  Future<ProductTopping> call({
    required int storeId,
    required String name,
    required int price,
  }) {
    return _repository.createTopping(
      storeId: storeId,
      name: name,
      price: price,
    );
  }
}
