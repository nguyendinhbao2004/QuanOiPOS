import '../../domain/entities/active_subscription.dart';
import '../../domain/entities/service_package.dart';

enum SubscriptionStatus { initial, loading, ready, error }

class SubscriptionState {
  final SubscriptionStatus status;
  final List<ServicePackage> plans;
  final ActiveSubscription? activeSubscription;
  final String? errorMessage;

  const SubscriptionState({
    required this.status,
    this.plans = const [],
    this.activeSubscription,
    this.errorMessage,
  });

  const SubscriptionState.initial()
    : status = SubscriptionStatus.initial,
      plans = const [],
      activeSubscription = null,
      errorMessage = null;

  bool get isLoading => status == SubscriptionStatus.loading;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    List<ServicePackage>? plans,
    ActiveSubscription? activeSubscription,
    String? errorMessage,
    bool clearError = false,
    bool clearActiveSubscription = false,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      activeSubscription: clearActiveSubscription
          ? null
          : (activeSubscription ?? this.activeSubscription),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
