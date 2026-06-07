import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/workspace_context/data/datasources/store_access_context_cache_storage_impl.dart';
import 'package:quan_oi/features/workspace_context/data/models/store_access_context_cache_model.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'saves and loads cached store access context by account and store',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final storage = StoreAccessContextCacheStorageImpl(preferences);

      await storage.save(
        StoreAccessContextCacheModel.fromEntity(
          accountId: 8,
          context: _accessContext,
        ),
      );

      final loaded = await storage.load(accountId: 8, storeId: 2);
      expect(loaded, isNotNull);
      expect(loaded?.accountId, 8);
      expect(loaded?.storeId, 2);
      expect(loaded?.toEntity().store.storeName, 'Buffet Poseidon');
      expect(
        loaded?.toEntity().permissions.map((permission) => permission.code),
        contains('DASHBOARD.VIEW'),
      );

      expect(await storage.load(accountId: 9, storeId: 2), isNull);
    },
  );

  test('clears corrupted cached store access context', () async {
    SharedPreferences.setMockInitialValues({
      'store_access_context_cache_8_2': '{bad json',
    });
    final preferences = await SharedPreferences.getInstance();
    final storage = StoreAccessContextCacheStorageImpl(preferences);

    final loaded = await storage.load(accountId: 8, storeId: 2);

    expect(loaded, isNull);
    expect(preferences.getString('store_access_context_cache_8_2'), isNull);
  });

  test('clear all removes every store access context cache entry', () async {
    SharedPreferences.setMockInitialValues({
      'store_access_context_cache_8_2': '{}',
      'store_access_context_cache_9_3': '{}',
      'unrelated_key': 'keep',
    });
    final preferences = await SharedPreferences.getInstance();
    final storage = StoreAccessContextCacheStorageImpl(preferences);

    await storage.clearAll();

    expect(preferences.getString('store_access_context_cache_8_2'), isNull);
    expect(preferences.getString('store_access_context_cache_9_3'), isNull);
    expect(preferences.getString('unrelated_key'), 'keep');
  });
}

const _accessContext = StoreAccessContext(
  store: Store(
    id: 2,
    ownerAccountId: 8,
    storeName: 'Buffet Poseidon',
    phone: '0961813466',
    address: 'TTTM Vincom Plaza',
    status: StoreStatus.active,
    isDeleted: false,
  ),
  permissions: [
    StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW'),
    StorePermission(permissionId: 3, code: 'STORE.UPDATE'),
  ],
);
