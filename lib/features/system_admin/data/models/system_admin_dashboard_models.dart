import '../../domain/entities/system_admin_dashboard.dart';

class SystemAdminDashboardOverviewModel {
  final DashboardOverview value;
  const SystemAdminDashboardOverviewModel(this.value);
  factory SystemAdminDashboardOverviewModel.fromJson(Object? json) {
    final map = _map(json);
    final metrics = _map(map['metrics']);
    final comparison = _map(map['comparison']);
    return SystemAdminDashboardOverviewModel(
      DashboardOverview(
        subscriptionRevenue: _double(metrics['subscriptionRevenue']),
        successfulPayments: _int(metrics['successfulPayments']),
        newSubscriptions: _int(metrics['newSubscriptions']),
        activeSubscriptions: _int(metrics['activeSubscriptions']),
        newStoreAccounts: _int(metrics['newStoreAccounts']),
        totalStoreAccounts: _int(metrics['totalStoreAccounts']),
        accountGrowthRate: _double(metrics['accountGrowthRate']),
        paidAccountRate: _double(metrics['paidAccountRate']),
        revenueComparison: _double(comparison['subscriptionRevenue']),
        paymentsComparison: _double(comparison['successfulPayments']),
        accountsComparison: _double(comparison['newStoreAccounts']),
      ),
    );
  }
}

class RevenueSeriesModel {
  final List<RevenuePoint> value;
  const RevenueSeriesModel(this.value);
  factory RevenueSeriesModel.fromJson(Object? json) => RevenueSeriesModel(
    _list(_map(json)['series']).map((item) {
      final map = _map(item);
      return RevenuePoint(
        period: _date(map['period']),
        revenue: _double(map['revenue']),
        successfulPayments: _int(map['successfulPayments']),
        newSubscriptions: _int(map['newSubscriptions']),
      );
    }).toList(),
  );
}

class PlanRevenueModel {
  final List<PlanRevenue> value;
  const PlanRevenueModel(this.value);
  factory PlanRevenueModel.fromJson(Object? json) => PlanRevenueModel(
    _list(_map(json)['items']).map((item) {
      final map = _map(item);
      return PlanRevenue(
        planId: _int(map['planId']),
        planName: _string(map['planName']),
        revenue: _double(map['revenue']),
        successfulPayments: _int(map['successfulPayments']),
        revenuePercentage: _double(map['revenuePercentage']),
      );
    }).toList(),
  );
}

class AccountGrowthModel {
  final List<AccountGrowthPoint> value;
  const AccountGrowthModel(this.value);
  factory AccountGrowthModel.fromJson(Object? json) => AccountGrowthModel(
    _list(_map(json)['series']).map((item) {
      final map = _map(item);
      return AccountGrowthPoint(
        period: _date(map['period']),
        newStoreAccounts: _int(map['newStoreAccounts']),
        totalStoreAccounts: _int(map['totalStoreAccounts']),
      );
    }).toList(),
  );
}

class SubscriptionDistributionModel {
  final List<SubscriptionSegment> segments;
  final int trialSubscriptions;
  const SubscriptionDistributionModel({
    required this.segments,
    required this.trialSubscriptions,
  });
  factory SubscriptionDistributionModel.fromJson(Object? json) {
    final map = _map(json);
    return SubscriptionDistributionModel(
      trialSubscriptions: _int(map['trialSubscriptions']),
      segments: _list(map['segments']).map((item) {
        final segment = _map(item);
        return SubscriptionSegment(
          status: _string(segment['status']),
          label: _string(segment['label']),
          count: _int(segment['count']),
          percentage: _double(segment['percentage']),
        );
      }).toList(),
    );
  }
}

class SubscriptionPaymentPageModel {
  final SubscriptionPaymentPage value;
  const SubscriptionPaymentPageModel(this.value);
  factory SubscriptionPaymentPageModel.fromJson(Object? json) {
    final map = _map(json);
    final pagination = _map(map['pagination']);
    return SubscriptionPaymentPageModel(
      SubscriptionPaymentPage(
        items: _list(map['items']).map((item) {
          final payment = _map(item);
          final account = _map(payment['account']);
          final plan = _map(payment['plan']);
          return SubscriptionPaymentItem(
            paymentId: _int(payment['paymentId']),
            subscriptionId: _int(payment['subscriptionId']),
            accountId: _int(account['id']),
            planId: _int(plan['id']),
            ownerName: _string(account['fullName']),
            email: _string(account['email']),
            planName: _string(plan['name']),
            amount: _double(payment['amount']),
            currency: _string(payment['currency'], fallback: 'VND'),
            paymentMethod: _string(payment['paymentMethod']),
            status: DashboardPaymentStatus.fromApiValue(payment['status']),
            paidAt: _nullableDate(payment['paidAt']),
            createdAt: _date(payment['createdAt']),
          );
        }).toList(),
        pageIndex: _int(pagination['pageIndex'], fallback: 1),
        pageSize: _int(pagination['pageSize'], fallback: 10),
        totalItems: _int(pagination['totalItems']),
        totalPages: _int(pagination['totalPages'], fallback: 1),
      ),
    );
  }
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : const {};
List<Object?> _list(Object? value) => value is List ? value : const [];
int _int(Object? value, {int fallback = 0}) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;
double _double(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
String _string(Object? value, {String fallback = ''}) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? fallback : result;
}

DateTime _date(Object? value) =>
    _nullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
DateTime? _nullableDate(Object? value) =>
    value is DateTime ? value : DateTime.tryParse(value?.toString() ?? '');
