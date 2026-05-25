import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/active_subscription.dart';
import '../../domain/entities/service_package.dart';
import '../providers/subscription_providers.dart';
import 'subscription_state.dart';

class SubscriptionNotifier extends AutoDisposeNotifier<SubscriptionState> {
  bool _initialLoadStarted = false;

  @override
  SubscriptionState build() {
    Future.microtask(loadPlans);
    return const SubscriptionState.initial();
  }

  Future<void> loadPlans() async {
    if (_initialLoadStarted && state.status == SubscriptionStatus.loading) {
      return;
    }

    _initialLoadStarted = true;
    state = state.copyWith(
      status: SubscriptionStatus.loading,
      clearError: true,
      clearActiveSubscription: true,
    );

    try {
      final loadPlansUseCase = ref.read(loadSubscriptionPlansUseCaseProvider);
      final loadActiveSubscriptionUseCase = ref.read(
        loadActiveSubscriptionUseCaseProvider,
      );
      final plansFuture = loadPlansUseCase();
      final activeSubscriptionFuture = loadActiveSubscriptionUseCase();
      final results = await Future.wait<Object?>([
        plansFuture,
        activeSubscriptionFuture,
      ]);
      final plans = results[0] as List<ServicePackage>;
      final activeSubscription = results[1] as ActiveSubscription?;
      state = SubscriptionState(
        status: SubscriptionStatus.ready,
        plans: plans,
        activeSubscription: activeSubscription,
      );
    } catch (error) {
      state = SubscriptionState(
        status: SubscriptionStatus.error,
        plans: state.plans,
        activeSubscription: state.activeSubscription,
        errorMessage: _cleanError(error),
      );
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
