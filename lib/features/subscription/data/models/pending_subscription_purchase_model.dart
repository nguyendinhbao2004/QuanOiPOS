import 'dart:convert';

import '../../domain/entities/pending_subscription_purchase.dart';

class PendingSubscriptionPurchaseModel {
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

  const PendingSubscriptionPurchaseModel({
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

  factory PendingSubscriptionPurchaseModel.fromEntity(
    PendingSubscriptionPurchase entity,
  ) {
    return PendingSubscriptionPurchaseModel(
      subscriptionId: entity.subscriptionId,
      paymentId: entity.paymentId,
      planId: entity.planId,
      orderCode: entity.orderCode,
      paymentLinkId: entity.paymentLinkId,
      planName: entity.planName,
      amount: entity.amount,
      paymentLink: entity.paymentLink,
      paymentStatus: entity.paymentStatus,
      subscriptionStatus: entity.subscriptionStatus,
      subscriptionExpiresAt: entity.subscriptionExpiresAt,
      paymentExpiresAt: entity.paymentExpiresAt,
      createdAt: entity.createdAt,
      canResumePayment: entity.canResumePayment,
      canCancel: entity.canCancel,
    );
  }

  factory PendingSubscriptionPurchaseModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid pending purchase data');
    }

    return PendingSubscriptionPurchaseModel(
      subscriptionId: _intValue(json['subscriptionId']),
      paymentId: _intValue(json['paymentId']),
      planId: _intValue(json['planId']),
      orderCode: _intValue(json['orderCode']),
      paymentLinkId: _stringValue(json['paymentLinkId']),
      planName: _stringValue(json['planName']),
      amount: _doubleValue(json['amount']),
      paymentLink: _stringValue(json['paymentLink']),
      paymentStatus: _stringValue(json['paymentStatus']),
      subscriptionStatus: _stringValue(json['subscriptionStatus']),
      subscriptionExpiresAt: _dateValue(
        json['subscriptionExpiresAt'] ?? json['expiresAt'],
      ),
      paymentExpiresAt: _dateValue(json['paymentExpiresAt']),
      createdAt: _dateValue(json['createdAt']),
      canResumePayment: _boolValue(json['canResumePayment'], fallback: true),
      canCancel: _boolValue(json['canCancel'], fallback: true),
    );
  }

  factory PendingSubscriptionPurchaseModel.fromStorage(String value) {
    return PendingSubscriptionPurchaseModel.fromJson(jsonDecode(value));
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'paymentId': paymentId,
      'planId': planId,
      'orderCode': orderCode,
      'paymentLinkId': paymentLinkId,
      'planName': planName,
      'amount': amount,
      'paymentLink': paymentLink,
      'paymentStatus': paymentStatus,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
      'paymentExpiresAt': paymentExpiresAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'canResumePayment': canResumePayment,
      'canCancel': canCancel,
    };
  }

  String toStorage() => jsonEncode(toJson());

  PendingSubscriptionPurchase toEntity() {
    return PendingSubscriptionPurchase(
      subscriptionId: subscriptionId,
      paymentId: paymentId,
      planId: planId,
      orderCode: orderCode,
      paymentLinkId: paymentLinkId,
      planName: planName,
      amount: amount,
      paymentLink: paymentLink,
      paymentStatus: paymentStatus,
      subscriptionStatus: subscriptionStatus,
      subscriptionExpiresAt: subscriptionExpiresAt,
      paymentExpiresAt: paymentExpiresAt,
      createdAt: createdAt,
      canResumePayment: canResumePayment,
      canCancel: canCancel,
    );
  }

  static String _stringValue(Object? value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static int _intValue(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static double _doubleValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  static DateTime? _dateValue(Object? value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static bool _boolValue(Object? value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }

    return fallback;
  }
}
