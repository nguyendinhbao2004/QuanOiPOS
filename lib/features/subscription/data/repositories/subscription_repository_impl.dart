import '../../domain/entities/active_subscription.dart';
import '../../domain/entities/service_package.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource _remoteDataSource;

  const SubscriptionRepositoryImpl(this._remoteDataSource);

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
}
