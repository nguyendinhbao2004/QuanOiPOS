import '../entities/active_subscription.dart';
import '../entities/service_package.dart';

abstract class SubscriptionRepository {
  Future<List<ServicePackage>> loadPlans();

  Future<ActiveSubscription?> loadActiveSubscription();
}
