enum DashboardGroupBy {
  day('day'),
  week('week'),
  month('month');

  final String apiValue;
  const DashboardGroupBy(this.apiValue);
}

enum DashboardPaymentStatus {
  all(null),
  pending('Pending'),
  completed('Completed'),
  failed('Failed'),
  refunded('Refunded');

  final String? apiValue;
  const DashboardPaymentStatus(this.apiValue);

  static DashboardPaymentStatus fromApiValue(Object? value) {
    final normalized = value?.toString().toLowerCase();
    return DashboardPaymentStatus.values.firstWhere(
      (status) => status.apiValue?.toLowerCase() == normalized,
      orElse: () => DashboardPaymentStatus.pending,
    );
  }
}

class SystemAdminDashboardQuery {
  final DateTime from;
  final DateTime to;
  final DashboardGroupBy groupBy;
  final int? planId;
  final DashboardPaymentStatus? paymentStatus;

  const SystemAdminDashboardQuery({
    required this.from,
    required this.to,
    required this.groupBy,
    this.planId,
    this.paymentStatus,
  });

  Map<String, dynamic> toQueryParameters() {
    final parameters = <String, dynamic>{
      'from': _dateOnlyUtc(from),
      'to': _dateOnlyUtc(to),
      'groupBy': groupBy.apiValue,
    };
    if (planId != null) parameters['planId'] = planId;
    if (paymentStatus?.apiValue != null) {
      parameters['paymentStatus'] = paymentStatus!.apiValue;
    }
    return parameters;
  }

  SystemAdminDashboardQuery copyWith({
    DateTime? from,
    DateTime? to,
    DashboardGroupBy? groupBy,
    int? planId,
    DashboardPaymentStatus? paymentStatus,
    bool clearPlan = false,
    bool clearPaymentStatus = false,
  }) => SystemAdminDashboardQuery(
    from: from ?? this.from,
    to: to ?? this.to,
    groupBy: groupBy ?? this.groupBy,
    planId: clearPlan ? null : planId ?? this.planId,
    paymentStatus: clearPaymentStatus
        ? null
        : paymentStatus ?? this.paymentStatus,
  );

  static String _dateOnlyUtc(DateTime value) {
    final utc = value.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';
  }
}

class DashboardOverview {
  final double subscriptionRevenue;
  final int successfulPayments;
  final int newSubscriptions;
  final int activeSubscriptions;
  final int newStoreAccounts;
  final int totalStoreAccounts;
  final double accountGrowthRate;
  final double paidAccountRate;
  final double revenueComparison;
  final double paymentsComparison;
  final double accountsComparison;

  const DashboardOverview({
    required this.subscriptionRevenue,
    required this.successfulPayments,
    required this.newSubscriptions,
    required this.activeSubscriptions,
    required this.newStoreAccounts,
    required this.totalStoreAccounts,
    required this.accountGrowthRate,
    required this.paidAccountRate,
    required this.revenueComparison,
    required this.paymentsComparison,
    required this.accountsComparison,
  });
}

class RevenuePoint {
  final DateTime period;
  final double revenue;
  final int successfulPayments;
  final int newSubscriptions;
  const RevenuePoint({
    required this.period,
    required this.revenue,
    required this.successfulPayments,
    required this.newSubscriptions,
  });
}

class PlanRevenue {
  final int planId;
  final String planName;
  final double revenue;
  final int successfulPayments;
  final double revenuePercentage;
  const PlanRevenue({
    required this.planId,
    required this.planName,
    required this.revenue,
    required this.successfulPayments,
    required this.revenuePercentage,
  });
}

class AccountGrowthPoint {
  final DateTime period;
  final int newStoreAccounts;
  final int totalStoreAccounts;
  const AccountGrowthPoint({
    required this.period,
    required this.newStoreAccounts,
    required this.totalStoreAccounts,
  });
}

class SubscriptionSegment {
  final String status;
  final String label;
  final int count;
  final double percentage;
  const SubscriptionSegment({
    required this.status,
    required this.label,
    required this.count,
    required this.percentage,
  });
}

class SubscriptionPaymentItem {
  final int paymentId;
  final int subscriptionId;
  final int accountId;
  final int planId;
  final String ownerName;
  final String email;
  final String planName;
  final double amount;
  final String currency;
  final String paymentMethod;
  final DashboardPaymentStatus status;
  final DateTime? paidAt;
  final DateTime createdAt;
  const SubscriptionPaymentItem({
    required this.paymentId,
    required this.subscriptionId,
    required this.accountId,
    required this.planId,
    required this.ownerName,
    required this.email,
    required this.planName,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.paidAt,
    required this.createdAt,
  });
}

class SubscriptionPaymentPage {
  final List<SubscriptionPaymentItem> items;
  final int pageIndex;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  const SubscriptionPaymentPage({
    required this.items,
    required this.pageIndex,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });
}

class SubscriptionDistributionData {
  final List<SubscriptionSegment> segments;
  final int trialSubscriptions;

  const SubscriptionDistributionData({
    required this.segments,
    required this.trialSubscriptions,
  });
}

class SystemAdminDashboardData {
  final DashboardOverview overview;
  final List<RevenuePoint> revenueSeries;
  final List<PlanRevenue> revenueByPlan;
  final List<AccountGrowthPoint> accountGrowth;
  final List<SubscriptionSegment> subscriptionDistribution;
  final int trialSubscriptions;
  final SubscriptionPaymentPage payments;
  const SystemAdminDashboardData({
    required this.overview,
    required this.revenueSeries,
    required this.revenueByPlan,
    required this.accountGrowth,
    required this.subscriptionDistribution,
    required this.trialSubscriptions,
    required this.payments,
  });
}

typedef DashboardFilters = SystemAdminDashboardQuery;
