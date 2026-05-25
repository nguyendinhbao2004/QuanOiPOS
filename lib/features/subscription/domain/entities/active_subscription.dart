class ActiveSubscription {
  final int id;
  final int accountId;
  final int planId;
  final String planName;
  final double price;
  final DateTime? startDate;
  final DateTime? endDate;
  final int daysRemaining;
  final bool isActive;
  final bool isExpired;
  final int maxStores;
  final int maxUsers;
  final String status;
  final bool autoRenew;
  final DateTime? cancelAt;

  const ActiveSubscription({
    required this.id,
    required this.accountId,
    required this.planId,
    required this.planName,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.daysRemaining,
    required this.isActive,
    required this.isExpired,
    required this.maxStores,
    required this.maxUsers,
    required this.status,
    required this.autoRenew,
    required this.cancelAt,
  });
}
