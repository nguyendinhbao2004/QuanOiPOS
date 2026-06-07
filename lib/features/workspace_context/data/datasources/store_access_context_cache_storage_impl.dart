import 'package:shared_preferences/shared_preferences.dart';

import '../models/store_access_context_cache_model.dart';
import 'store_access_context_cache_storage.dart';

class StoreAccessContextCacheStorageImpl
    implements StoreAccessContextCacheStorage {
  static const _storageKeyPrefix = 'store_access_context_cache';

  final SharedPreferences _preferences;

  const StoreAccessContextCacheStorageImpl(this._preferences);

  @override
  Future<StoreAccessContextCacheModel?> load({
    required int accountId,
    required int storeId,
  }) async {
    final value = _preferences.getString(_storageKey(accountId, storeId));
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      final cache = StoreAccessContextCacheModel.fromStorage(value);
      if (cache.accountId != accountId || cache.storeId != storeId) {
        await clear(accountId: accountId, storeId: storeId);
        return null;
      }

      return cache;
    } on FormatException {
      await clear(accountId: accountId, storeId: storeId);
      return null;
    }
  }

  @override
  Future<void> save(StoreAccessContextCacheModel cache) async {
    await _preferences.setString(
      _storageKey(cache.accountId, cache.storeId),
      cache.toStorage(),
    );
  }

  @override
  Future<void> clear({required int accountId, required int storeId}) async {
    await _preferences.remove(_storageKey(accountId, storeId));
  }

  @override
  Future<void> clearAll() async {
    final keys = _preferences
        .getKeys()
        .where((key) => key.startsWith(_storageKeyPrefix))
        .toList();

    for (final key in keys) {
      await _preferences.remove(key);
    }
  }

  static String _storageKey(int accountId, int storeId) {
    return '${_storageKeyPrefix}_${accountId}_$storeId';
  }
}
