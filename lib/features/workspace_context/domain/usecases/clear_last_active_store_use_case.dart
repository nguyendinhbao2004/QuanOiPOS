import '../../../../core/storage/last_active_store_storage.dart';

class ClearLastActiveStoreUseCase {
  final LastActiveStoreStorage _storage;

  const ClearLastActiveStoreUseCase(this._storage);

  Future<void> call() {
    return _storage.clearLastActiveStoreId();
  }
}
