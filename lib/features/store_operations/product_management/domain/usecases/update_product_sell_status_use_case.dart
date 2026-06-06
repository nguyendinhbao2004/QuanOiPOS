import '../repositories/product_management_repository.dart';

class UpdateProductSellStatusUseCase {
  final ProductManagementRepository _repository;

  const UpdateProductSellStatusUseCase(this._repository);

  Future<void> call({required int productId, required bool isSell}) {
    return _repository.updateProductSellStatus(
      productId: productId,
      isSell: isSell,
    );
  }
}
