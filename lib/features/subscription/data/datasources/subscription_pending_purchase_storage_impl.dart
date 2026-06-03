import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_subscription_purchase_model.dart';
import 'subscription_pending_purchase_storage.dart';

class SubscriptionPendingPurchaseStorageImpl
    implements SubscriptionPendingPurchaseStorage {
  static const _storageKeyPrefix = 'subscription_pending_purchase';

  final SharedPreferences _preferences;

  const SubscriptionPendingPurchaseStorageImpl(this._preferences);

  @override
  Future<void> save({
    required int accountId,
    required PendingSubscriptionPurchaseModel purchase,
  }) async {
    await _preferences.setString(_storageKey(accountId), purchase.toStorage());
  }

  @override
  Future<PendingSubscriptionPurchaseModel?> load({
    required int accountId,
  }) async {
    final value = _preferences.getString(_storageKey(accountId));
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      return PendingSubscriptionPurchaseModel.fromStorage(value);
    } on FormatException {
      await clear(accountId: accountId);
      return null;
    }
  }

  @override
  Future<void> clear({required int accountId}) async {
    await _preferences.remove(_storageKey(accountId));
  }

  static String _storageKey(int accountId) => '${_storageKeyPrefix}_$accountId';
}
