import '../../domain/entities/store_access_context.dart';
import '../../domain/entities/store.dart';
import '../../domain/entities/store_permission.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../datasources/store_access_context_cache_storage.dart';
import '../datasources/workspace_remote_data_source.dart';
import '../models/create_store_request_model.dart';
import '../models/store_access_context_cache_model.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  final WorkspaceRemoteDataSource _remoteDataSource;
  final StoreAccessContextCacheStorage? _cacheStorage;

  const WorkspaceRepositoryImpl(this._remoteDataSource, [this._cacheStorage]);

  @override
  Future<List<Store>> loadMyStores() async {
    final stores = await _remoteDataSource.getMyStores();
    return stores
        .where((store) => !store.isDeleted)
        .map((store) => store.toEntity())
        .toList();
  }

  @override
  Future<Store> createStore({
    required String storeName,
    required String phone,
    required String address,
  }) async {
    final store = await _remoteDataSource.createStore(
      CreateStoreRequestModel(
        storeName: storeName,
        phone: phone,
        address: address,
      ),
    );
    return store.toEntity();
  }

  @override
  Future<Store> loadStoreById(int storeId) async {
    final store = await _remoteDataSource.getStoreById(storeId);
    return store.toEntity();
  }

  @override
  Future<List<StorePermission>> loadMyStorePermissions(int storeId) async {
    final permissions = await _remoteDataSource.getMyStorePermissions(storeId);
    return permissions.map((permission) => permission.toEntity()).toList();
  }

  @override
  Future<StoreAccessContext> loadStoreAccessContext(int storeId) async {
    final store = await loadStoreById(storeId);
    final permissions = await loadMyStorePermissions(storeId);

    return StoreAccessContext(store: store, permissions: permissions);
  }

  @override
  Future<StoreAccessContext?> loadCachedStoreAccessContext({
    required int accountId,
    required int storeId,
  }) async {
    final cache = await _cacheStorage?.load(
      accountId: accountId,
      storeId: storeId,
    );
    return cache?.toEntity();
  }

  @override
  Future<void> saveStoreAccessContextCache({
    required int accountId,
    required StoreAccessContext context,
  }) async {
    await _cacheStorage?.save(
      StoreAccessContextCacheModel.fromEntity(
        accountId: accountId,
        context: context,
      ),
    );
  }

  @override
  Future<void> clearStoreAccessContextCache({
    required int accountId,
    required int storeId,
  }) async {
    await _cacheStorage?.clear(accountId: accountId, storeId: storeId);
  }

  @override
  Future<void> clearAllStoreAccessContextCache() async {
    await _cacheStorage?.clearAll();
  }
}
