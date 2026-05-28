import '../entities/store_access_context.dart';
import '../entities/store.dart';
import '../entities/store_permission.dart';

abstract class WorkspaceRepository {
  Future<List<Store>> loadMyStores();

  Future<Store> loadStoreById(int storeId);

  Future<List<StorePermission>> loadMyStorePermissions(int storeId);

  Future<StoreAccessContext> loadStoreAccessContext(int storeId);
}
