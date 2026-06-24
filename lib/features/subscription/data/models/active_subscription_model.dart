import '../../domain/entities/active_subscription.dart';

class ActiveSubscriptionModel {
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
  final bool isTrial;
  final bool autoRenew;
  final DateTime? cancelAt;

  const ActiveSubscriptionModel({
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
    required this.isTrial,
    required this.autoRenew,
    required this.cancelAt,
  });

  factory ActiveSubscriptionModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid active subscription data');
    }

    return ActiveSubscriptionModel(
      id: _intValue(json['id']),
      accountId: _intValue(json['accountId']),
      planId: _intValue(json['planId']),
      planName: _stringValue(json['planName']),
      price: _doubleValue(json['price']),
      startDate: _dateValue(json['startDate']),
      endDate: _dateValue(json['endDate']),
      daysRemaining: _intValue(json['daysRemaining']),
      isActive: _boolValue(json['isActive']),
      isExpired: _boolValue(json['isExpired']),
      maxStores: _intValue(json['maxStores']),
      maxUsers: _intValue(json['maxUsers']),
      status: _stringValue(json['status']),
      isTrial: _boolValue(json['isTrial']),
      autoRenew: _boolValue(json['autoRenew']),
      cancelAt: _dateValue(json['cancelAt']),
    );
  }

  ActiveSubscription toEntity() {
    return ActiveSubscription(
      id: id,
      accountId: accountId,
      planId: planId,
      planName: planName,
      price: price,
      startDate: startDate,
      endDate: endDate,
      daysRemaining: daysRemaining,
      isActive: isActive,
      isExpired: isExpired,
      maxStores: maxStores,
      maxUsers: maxUsers,
      status: status,
      isTrial: isTrial,
      autoRenew: autoRenew,
      cancelAt: cancelAt,
    );
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
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

  static bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return false;
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
}
