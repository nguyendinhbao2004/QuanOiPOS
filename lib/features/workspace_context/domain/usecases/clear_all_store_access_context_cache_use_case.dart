import '../repositories/workspace_repository.dart';

class ClearAllStoreAccessContextCacheUseCase {
  final WorkspaceRepository _repository;

  const ClearAllStoreAccessContextCacheUseCase(this._repository);

  Future<void> call() {
    return _repository.clearAllStoreAccessContextCache();
  }
}
