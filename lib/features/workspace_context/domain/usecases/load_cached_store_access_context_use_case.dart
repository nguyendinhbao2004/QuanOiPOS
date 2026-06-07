import '../entities/store_access_context.dart';
import '../repositories/workspace_repository.dart';

class LoadCachedStoreAccessContextUseCase {
  final WorkspaceRepository _repository;

  const LoadCachedStoreAccessContextUseCase(this._repository);

  Future<StoreAccessContext?> call({
    required int accountId,
    required int storeId,
  }) {
    return _repository.loadCachedStoreAccessContext(
      accountId: accountId,
      storeId: storeId,
    );
  }
}
