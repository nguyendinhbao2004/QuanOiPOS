abstract class LastActiveStoreStorage {
  Future<int?> getLastActiveStoreId();

  Future<void> saveLastActiveStoreId(int storeId);

  Future<void> clearLastActiveStoreId();
}
