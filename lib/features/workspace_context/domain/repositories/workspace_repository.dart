import '../entities/store_access_context.dart';
import '../entities/store.dart';
import '../entities/store_permission.dart';

abstract class WorkspaceRepository {
  Future<List<Store>> loadMyStores();

  Future<Store> createStore({
    required String storeName,
    required String phone,
    required String address,
  });

  Future<Store> loadStoreById(int storeId);

  Future<List<StorePermission>> loadMyStorePermissions(int storeId);

  Future<StoreAccessContext> loadStoreAccessContext(int storeId);

  Future<StoreAccessContext?> loadCachedStoreAccessContext({
    required int accountId,
    required int storeId,
  });

  Future<void> saveStoreAccessContextCache({
    required int accountId,
    required StoreAccessContext context,
  });

  Future<void> clearStoreAccessContextCache({
    required int accountId,
    required int storeId,
  });

  Future<void> clearAllStoreAccessContextCache();
}
