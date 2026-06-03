import '../../domain/entities/store_access_context.dart';
import '../../domain/entities/store.dart';
import '../../domain/entities/store_permission.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../datasources/workspace_remote_data_source.dart';
import '../models/create_store_request_model.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  final WorkspaceRemoteDataSource _remoteDataSource;

  const WorkspaceRepositoryImpl(this._remoteDataSource);

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
}
