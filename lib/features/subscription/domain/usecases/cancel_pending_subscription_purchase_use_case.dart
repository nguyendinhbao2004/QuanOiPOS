import '../repositories/subscription_repository.dart';

class CancelPendingSubscriptionPurchaseUseCase {
  final SubscriptionRepository _repository;

  const CancelPendingSubscriptionPurchaseUseCase(this._repository);

  Future<void> call({required int subscriptionId}) {
    return _repository.cancelPendingPurchase(subscriptionId: subscriptionId);
  }
}
