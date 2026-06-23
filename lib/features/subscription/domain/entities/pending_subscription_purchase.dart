class PendingSubscriptionPurchase {
  final int subscriptionId;
  final int paymentId;
  final int planId;
  final int orderCode;
  final String paymentLinkId;
  final String planName;
  final double amount;
  final String paymentLink;
  final String paymentStatus;
  final String subscriptionStatus;
  final DateTime? subscriptionExpiresAt;
  final DateTime? paymentExpiresAt;
  final DateTime? createdAt;
  final bool canResumePayment;
  final bool canCancel;

  const PendingSubscriptionPurchase({
    required this.subscriptionId,
    required this.paymentId,
    this.planId = 0,
    required this.orderCode,
    this.paymentLinkId = '',
    required this.planName,
    required this.amount,
    required this.paymentLink,
    this.paymentStatus = '',
    this.subscriptionStatus = '',
    this.subscriptionExpiresAt,
    this.paymentExpiresAt,
    this.createdAt,
    this.canResumePayment = true,
    this.canCancel = true,
  });
}
