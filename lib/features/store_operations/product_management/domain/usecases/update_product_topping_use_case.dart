import '../entities/product_topping.dart';
import '../repositories/product_management_repository.dart';

class UpdateProductToppingUseCase {
  final ProductManagementRepository _repository;

  const UpdateProductToppingUseCase(this._repository);

  Future<ProductTopping> call({
    required int toppingId,
    required String name,
    required int price,
  }) {
    return _repository.updateTopping(
      toppingId: toppingId,
      name: name,
      price: price,
    );
  }
}
