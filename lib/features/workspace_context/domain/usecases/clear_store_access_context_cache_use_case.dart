import '../repositories/workspace_repository.dart';

class ClearStoreAccessContextCacheUseCase {
  final WorkspaceRepository _repository;

  const ClearStoreAccessContextCacheUseCase(this._repository);

  Future<void> call({required int accountId, required int storeId}) {
    return _repository.clearStoreAccessContextCache(
      accountId: accountId,
      storeId: storeId,
    );
  }
}
