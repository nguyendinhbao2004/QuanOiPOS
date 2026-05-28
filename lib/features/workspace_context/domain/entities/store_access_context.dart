import 'store.dart';
import 'store_permission.dart';

class StoreAccessContext {
  final Store store;
  final List<StorePermission> permissions;

  const StoreAccessContext({required this.store, required this.permissions});

  Set<String> get permissionCodes {
    return permissions.map((permission) => permission.code).toSet();
  }

  bool can(String permissionCode) {
    return permissionCodes.contains(permissionCode);
  }
}
