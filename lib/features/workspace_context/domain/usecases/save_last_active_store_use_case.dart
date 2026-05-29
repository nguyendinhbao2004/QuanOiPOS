import '../../../../core/storage/last_active_store_storage.dart';

class SaveLastActiveStoreUseCase {
  final LastActiveStoreStorage _storage;

  const SaveLastActiveStoreUseCase(this._storage);

  Future<void> call(int storeId) {
    return _storage.saveLastActiveStoreId(storeId);
  }
}
