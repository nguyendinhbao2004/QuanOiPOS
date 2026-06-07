import '../entities/store_access_context.dart';
import '../repositories/workspace_repository.dart';

class SaveStoreAccessContextCacheUseCase {
  final WorkspaceRepository _repository;

  const SaveStoreAccessContextCacheUseCase(this._repository);

  Future<void> call({
    required int accountId,
    required StoreAccessContext context,
  }) {
    return _repository.saveStoreAccessContextCache(
      accountId: accountId,
      context: context,
    );
  }
}
