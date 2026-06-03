import '../models/pending_subscription_purchase_model.dart';

abstract class SubscriptionPendingPurchaseStorage {
  Future<void> save({
    required int accountId,
    required PendingSubscriptionPurchaseModel purchase,
  });

  Future<PendingSubscriptionPurchaseModel?> load({required int accountId});

  Future<void> clear({required int accountId});
}
