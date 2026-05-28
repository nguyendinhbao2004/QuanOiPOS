import '../entities/store_access_context.dart';
import '../repositories/workspace_repository.dart';

class LoadStoreAccessContextUseCase {
  final WorkspaceRepository _repository;

  const LoadStoreAccessContextUseCase(this._repository);

  Future<StoreAccessContext> call(int storeId) {
    return _repository.loadStoreAccessContext(storeId);
  }
}
