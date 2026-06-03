import '../entities/store.dart';
import '../repositories/workspace_repository.dart';

class CreateStoreUseCase {
  final WorkspaceRepository _repository;

  const CreateStoreUseCase(this._repository);

  Future<Store> call({
    required String storeName,
    required String phone,
    required String address,
  }) {
    return _repository.createStore(
      storeName: storeName,
      phone: phone,
      address: address,
    );
  }
}
