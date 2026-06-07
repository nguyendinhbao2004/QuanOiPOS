import '../models/store_access_context_cache_model.dart';

abstract class StoreAccessContextCacheStorage {
  Future<StoreAccessContextCacheModel?> load({
    required int accountId,
    required int storeId,
  });

  Future<void> save(StoreAccessContextCacheModel cache);

  Future<void> clear({required int accountId, required int storeId});

  Future<void> clearAll();
}
