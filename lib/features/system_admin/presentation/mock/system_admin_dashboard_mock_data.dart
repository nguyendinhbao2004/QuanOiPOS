enum DashboardGroupBy { day, week, month }

enum DashboardPaymentStatus { all, pending, completed, failed, refunded }

enum DashboardLoadStatus { loading, empty, error, ready }

class DashboardFilters {
  final DateTime from;
  final DateTime to;
  final DashboardGroupBy groupBy;
  final int? planId;
  final DashboardPaymentStatus paymentStatus;

  const DashboardFilters({
    required this.from,
    required this.to,
    required this.groupBy,
    required this.planId,
    required this.paymentStatus,
  });

  DashboardFilters copyWith({
    DateTime? from,
    DateTime? to,
    DashboardGroupBy? groupBy,
    int? planId,
    bool clearPlan = false,
    DashboardPaymentStatus? paymentStatus,
  }) {
    return DashboardFilters(
      from: from ?? this.from,
      to: to ?? this.to,
      groupBy: groupBy ?? this.groupBy,
      planId: clearPlan ? null : planId ?? this.planId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}

class DashboardOverview {
  final int subscriptionRevenue;
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
  final int revenue;
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
  final int revenue;
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
  final int planId;
  final String ownerName;
  final String email;
  final String planName;
  final int amount;
  final String paymentMethod;
  final DashboardPaymentStatus status;
  final DateTime? paidAt;
  final DateTime createdAt;

  const SubscriptionPaymentItem({
    required this.paymentId,
    required this.planId,
    required this.ownerName,
    required this.email,
    required this.planName,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.paidAt,
    required this.createdAt,
  });
}

class SystemAdminDashboardData {
  final DashboardOverview overview;
  final List<RevenuePoint> revenueSeries;
  final List<PlanRevenue> revenueByPlan;
  final List<AccountGrowthPoint> accountGrowth;
  final List<SubscriptionSegment> subscriptionDistribution;
  final int trialSubscriptions;
  final List<SubscriptionPaymentItem> payments;

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

abstract final class SystemAdminDashboardMockData {
  // TODO: Replace this fixture with the System Admin dashboard APIs.
  static final SystemAdminDashboardData data = SystemAdminDashboardData(
    overview: const DashboardOverview(
      subscriptionRevenue: 18472000,
      successfulPayments: 62,
      newSubscriptions: 47,
      activeSubscriptions: 39,
      newStoreAccounts: 68,
      totalStoreAccounts: 426,
      accountGrowthRate: 7.94,
      paidAccountRate: 11.27,
      revenueComparison: 14.8,
      paymentsComparison: 10.7,
      accountsComparison: -2.9,
    ),
    revenueSeries: List.generate(11, (index) {
      const revenues = [
        1196000,
        1495000,
        897000,
        2093000,
        1794000,
        1196000,
        2392000,
        1495000,
        2093000,
        897000,
        2994000,
      ];
      const payments = [4, 5, 3, 7, 6, 4, 8, 5, 7, 3, 10];
      const subscriptions = [3, 4, 2, 5, 4, 3, 6, 4, 5, 2, 9];
      return RevenuePoint(
        period: DateTime(2026, 6, index + 1),
        revenue: revenues[index],
        successfulPayments: payments[index],
        newSubscriptions: subscriptions[index],
      );
    }),
    revenueByPlan: const [
      PlanRevenue(
        planId: 2,
        planName: 'Pro',
        revenue: 10465000,
        successfulPayments: 35,
        revenuePercentage: 56.65,
      ),
      PlanRevenue(
        planId: 3,
        planName: 'Enterprise',
        revenue: 5593000,
        successfulPayments: 11,
        revenuePercentage: 30.28,
      ),
      PlanRevenue(
        planId: 1,
        planName: 'Basic',
        revenue: 2414000,
        successfulPayments: 16,
        revenuePercentage: 13.07,
      ),
    ],
    accountGrowth: List.generate(11, (index) {
      const newAccounts = [5, 8, 4, 7, 6, 9, 3, 8, 7, 5, 6];
      const totals = [363, 371, 375, 382, 388, 397, 400, 408, 415, 420, 426];
      return AccountGrowthPoint(
        period: DateTime(2026, 6, index + 1),
        newStoreAccounts: newAccounts[index],
        totalStoreAccounts: totals[index],
      );
    }),
    subscriptionDistribution: const [
      SubscriptionSegment(
        status: 'ACTIVE',
        label: 'Đang hoạt động',
        count: 39,
        percentage: 60.94,
      ),
      SubscriptionSegment(
        status: 'PENDING',
        label: 'Chờ thanh toán',
        count: 6,
        percentage: 9.38,
      ),
      SubscriptionSegment(
        status: 'EXPIRED',
        label: 'Đã hết hạn',
        count: 14,
        percentage: 21.87,
      ),
      SubscriptionSegment(
        status: 'CANCELLED',
        label: 'Đã hủy',
        count: 5,
        percentage: 7.81,
      ),
    ],
    trialSubscriptions: 9,
    payments: [
      _payment(
        1062,
        2,
        'Nguyễn Minh Anh',
        'minhanh@quanoi.vn',
        'Pro',
        299000,
        DashboardPaymentStatus.completed,
        11,
        9,
        42,
      ),
      _payment(
        1061,
        3,
        'Trần Quốc Bảo',
        'quocbao@quanoi.vn',
        'Enterprise',
        599000,
        DashboardPaymentStatus.completed,
        11,
        8,
        15,
      ),
      _payment(
        1060,
        1,
        'Lê Thu Hà',
        'thuha@quanoi.vn',
        'Basic',
        149000,
        DashboardPaymentStatus.pending,
        10,
        16,
        20,
      ),
      _payment(
        1059,
        2,
        'Phạm Gia Huy',
        'giahuy@quanoi.vn',
        'Pro',
        299000,
        DashboardPaymentStatus.failed,
        10,
        14,
        5,
      ),
      _payment(
        1058,
        2,
        'Võ Hoàng Lan',
        'hoanglan@quanoi.vn',
        'Pro',
        299000,
        DashboardPaymentStatus.completed,
        9,
        11,
        34,
      ),
      _payment(
        1057,
        1,
        'Đỗ Hải Nam',
        'hainam@quanoi.vn',
        'Basic',
        149000,
        DashboardPaymentStatus.refunded,
        8,
        10,
        8,
      ),
      _payment(
        1056,
        3,
        'Bùi Ngọc Mai',
        'ngocmai@quanoi.vn',
        'Enterprise',
        599000,
        DashboardPaymentStatus.completed,
        7,
        15,
        51,
      ),
      _payment(
        1055,
        2,
        'Đặng Tuấn Kiệt',
        'tuankiet@quanoi.vn',
        'Pro',
        299000,
        DashboardPaymentStatus.completed,
        6,
        13,
        27,
      ),
      _payment(
        1054,
        1,
        'Hồ Mỹ Linh',
        'mylinh@quanoi.vn',
        'Basic',
        149000,
        DashboardPaymentStatus.completed,
        5,
        9,
        16,
      ),
      _payment(
        1053,
        2,
        'Ngô Thanh Sơn',
        'thanhson@quanoi.vn',
        'Pro',
        299000,
        DashboardPaymentStatus.pending,
        4,
        17,
        44,
      ),
      _payment(
        1052,
        3,
        'Dương Khánh Vy',
        'khanhvy@quanoi.vn',
        'Enterprise',
        599000,
        DashboardPaymentStatus.completed,
        3,
        8,
        3,
      ),
      _payment(
        1051,
        2,
        'Mai Đức Long',
        'duclong@quanoi.vn',
        'Pro',
        299000,
        DashboardPaymentStatus.completed,
        2,
        12,
        39,
      ),
    ],
  );

  static SubscriptionPaymentItem _payment(
    int id,
    int planId,
    String owner,
    String email,
    String plan,
    int amount,
    DashboardPaymentStatus status,
    int day,
    int hour,
    int minute,
  ) {
    final createdAt = DateTime.utc(2026, 6, day, hour, minute);
    return SubscriptionPaymentItem(
      paymentId: id,
      planId: planId,
      ownerName: owner,
      email: email,
      planName: plan,
      amount: amount,
      paymentMethod: 'PayOS',
      status: status,
      paidAt:
          status == DashboardPaymentStatus.completed ||
              status == DashboardPaymentStatus.refunded
          ? createdAt.add(const Duration(minutes: 3))
          : null,
      createdAt: createdAt,
    );
  }
}
