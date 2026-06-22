import 'dart:convert';

import '../../domain/entities/system_admin_subscription_plan.dart';

class SystemAdminSubscriptionPlanModel {
  final int id;
  final String name;
  final double price;
  final int durationDays;
  final int maxStores;
  final int maxUsers;
  final String? features;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SystemAdminSubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.maxStores,
    required this.maxUsers,
    required this.features,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SystemAdminSubscriptionPlanModel.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    return SystemAdminSubscriptionPlanModel(
      id: _int(map['id']),
      name: map['name']?.toString() ?? '',
      price: _double(map['price']),
      durationDays: _int(map['durationDays']),
      maxStores: _int(map['maxStores']),
      maxUsers: _int(map['maxUsers']),
      features: map['features']?.toString(),
      isActive:
          map['isActive'] == true || map['isActive']?.toString() == 'true',
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  SystemAdminSubscriptionPlan toEntity() => SystemAdminSubscriptionPlan(
    id: id,
    name: name,
    price: price,
    durationDays: durationDays,
    maxStores: maxStores,
    maxUsers: maxUsers,
    features: _features(features),
    isActive: isActive,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class SystemAdminPlanSummaryModel {
  final int totalPlans;
  final int activePlans;
  final int inactivePlans;
  final List<PlanUsage> planUsage;

  const SystemAdminPlanSummaryModel({
    required this.totalPlans,
    required this.activePlans,
    required this.inactivePlans,
    required this.planUsage,
  });

  factory SystemAdminPlanSummaryModel.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    final rawUsage = map['planUsage'];
    return SystemAdminPlanSummaryModel(
      totalPlans: _int(map['totalPlans']),
      activePlans: _int(map['activePlans']),
      inactivePlans: _int(map['inactivePlans']),
      planUsage: rawUsage is List
          ? rawUsage
                .whereType<Map<String, dynamic>>()
                .map(
                  (item) => PlanUsage(
                    planId: _int(item['planId']),
                    planName: item['planName']?.toString() ?? '',
                    activeStoreCount: _int(item['activeStoreCount']),
                  ),
                )
                .toList()
          : const [],
    );
  }

  SystemAdminPlanSummary toEntity() => SystemAdminPlanSummary(
    totalPlans: totalPlans,
    activePlans: activePlans,
    inactivePlans: inactivePlans,
    planUsage: planUsage,
  );
}

class SystemAdminPlanPageModel {
  final List<SystemAdminSubscriptionPlanModel> items;
  final int pageIndex;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  const SystemAdminPlanPageModel({
    required this.items,
    required this.pageIndex,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory SystemAdminPlanPageModel.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    final pagination = map['pagination'] is Map<String, dynamic>
        ? map['pagination'] as Map<String, dynamic>
        : <String, dynamic>{};
    final rawItems = map['items'];
    return SystemAdminPlanPageModel(
      items: rawItems is List
          ? rawItems.map(SystemAdminSubscriptionPlanModel.fromJson).toList()
          : const [],
      pageIndex: _int(pagination['pageIndex'], fallback: 1),
      pageSize: _int(pagination['pageSize'], fallback: 10),
      totalItems: _int(pagination['totalItems']),
      totalPages: _int(pagination['totalPages'], fallback: 1),
    );
  }

  SystemAdminPlanPage toEntity() => SystemAdminPlanPage(
    items: items.map((item) => item.toEntity()).toList(),
    pageIndex: pageIndex,
    pageSize: pageSize,
    totalItems: totalItems,
    totalPages: totalPages,
  );
}

class UpsertSystemAdminSubscriptionPlanModel {
  final UpsertSystemAdminSubscriptionPlan plan;
  const UpsertSystemAdminSubscriptionPlanModel(this.plan);
  Map<String, dynamic> toJson() => {
    'name': plan.name,
    'price': plan.price,
    'durationDays': plan.durationDays,
    'maxStores': plan.maxStores,
    'maxUsers': plan.maxUsers,
    'features': plan.features.isEmpty ? null : jsonEncode(plan.features),
    'isActive': plan.isActive,
  };
}

int _int(Object? value, {int fallback = 0}) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;
double _double(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
List<String> _features(String? value) {
  if (value == null || value.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(value);
    if (decoded is List) return decoded.map((item) => item.toString()).toList();
  } on FormatException {
    // A legacy value is still displayable as a single feature.
  }
  return [value];
}
