import '../../../../core/storage/last_active_store_storage.dart';

class LoadLastActiveStoreUseCase {
  final LastActiveStoreStorage _storage;

  const LoadLastActiveStoreUseCase(this._storage);

  Future<int?> call() {
    return _storage.getLastActiveStoreId();
  }
}
