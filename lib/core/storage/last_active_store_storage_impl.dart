import 'package:shared_preferences/shared_preferences.dart';

import 'last_active_store_storage.dart';

class LastActiveStoreStorageImpl implements LastActiveStoreStorage {
  final SharedPreferences _prefs;

  const LastActiveStoreStorageImpl(this._prefs);

  static const _lastActiveStoreKey = 'last_active_store_id';

  @override
  Future<int?> getLastActiveStoreId() async {
    return _prefs.getInt(_lastActiveStoreKey);
  }

  @override
  Future<void> saveLastActiveStoreId(int storeId) async {
    await _prefs.setInt(_lastActiveStoreKey, storeId);
  }

  @override
  Future<void> clearLastActiveStoreId() async {
    await _prefs.remove(_lastActiveStoreKey);
  }
}
