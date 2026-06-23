import '../../../../core/storage/session_snapshot_storage.dart';
import '../../domain/entities/active_subscription.dart';
import '../../domain/entities/pending_subscription_purchase.dart';
import '../../domain/entities/purchase_subscription_result.dart';
import '../../domain/entities/service_package.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_pending_purchase_storage.dart';
import '../datasources/subscription_remote_data_source.dart';
import '../models/purchase_subscription_request_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource _remoteDataSource;
  final SubscriptionPendingPurchaseStorage _pendingPurchaseStorage;
  final SessionSnapshotStorage _sessionSnapshotStorage;

  const SubscriptionRepositoryImpl(
    this._remoteDataSource,
    this._pendingPurchaseStorage,
    this._sessionSnapshotStorage,
  );

  @override
  Future<List<ServicePackage>> loadPlans() async {
    final plans = await _remoteDataSource.getSubscriptionPlans();
    return plans
        .where((plan) => !plan.isDeleted)
        .map((plan) => plan.toEntity())
        .toList();
  }

  @override
  Future<ActiveSubscription?> loadActiveSubscription() async {
    final subscription = await _remoteDataSource.getActiveSubscription();
    return subscription?.toEntity();
  }

  @override
  Future<PurchaseSubscriptionResult> purchaseSubscription({
    required int planId,
    bool autoRenew = true,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    final result = await _remoteDataSource.purchaseSubscription(
      PurchaseSubscriptionRequestModel(
        planId: planId,
        autoRenew: autoRenew,
        returnUrl: returnUrl,
        cancelUrl: cancelUrl,
      ),
    );
    return result.toEntity();
  }

  @override
  Future<PendingSubscriptionPurchase?> loadPendingPurchase() async {
    final purchase = await _remoteDataSource.getPendingPurchase();
    return purchase?.toEntity();
  }

  @override
  Future<void> clearPendingPurchase() async {
    final accountId = await _currentAccountId();
    if (accountId == null) {
      return;
    }

    await _pendingPurchaseStorage.clear(accountId: accountId);
  }

  @override
  Future<void> cancelPendingPurchase({required int subscriptionId}) async {
    await _remoteDataSource.cancelPendingPurchase(
      subscriptionId: subscriptionId,
    );
    await clearPendingPurchase();
  }

  Future<int?> _currentAccountId() async {
    final snapshot = await _sessionSnapshotStorage.getSnapshot();
    final accountId = snapshot?.accountId ?? 0;
    return accountId > 0 ? accountId : null;
  }
}
