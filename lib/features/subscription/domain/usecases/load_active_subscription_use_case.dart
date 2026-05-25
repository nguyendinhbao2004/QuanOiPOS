import '../entities/active_subscription.dart';
import '../repositories/subscription_repository.dart';

class LoadActiveSubscriptionUseCase {
  final SubscriptionRepository _repository;

  const LoadActiveSubscriptionUseCase(this._repository);

  Future<ActiveSubscription?> call() {
    return _repository.loadActiveSubscription();
  }
}
