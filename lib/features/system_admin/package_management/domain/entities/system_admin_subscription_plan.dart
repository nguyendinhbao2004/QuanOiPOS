enum SystemAdminPlanStatus {
  all('all'),
  active('active'),
  inactive('inactive');

  final String apiValue;
  const SystemAdminPlanStatus(this.apiValue);
}

class SystemAdminSubscriptionPlan {
  final int id;
  final String name;
  final double price;
  final int durationDays;
  final int maxStores;
  final int maxUsers;
  final List<String> features;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SystemAdminSubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.maxStores,
    required this.maxUsers,
    required this.features,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });
}

class PlanUsage {
  final int planId;
  final String planName;
  final int activeStoreCount;

  const PlanUsage({
    required this.planId,
    required this.planName,
    required this.activeStoreCount,
  });
}

class SystemAdminPlanSummary {
  final int totalPlans;
  final int activePlans;
  final int inactivePlans;
  final List<PlanUsage> planUsage;

  const SystemAdminPlanSummary({
    required this.totalPlans,
    required this.activePlans,
    required this.inactivePlans,
    required this.planUsage,
  });
}

class SystemAdminPlanPage {
  final List<SystemAdminSubscriptionPlan> items;
  final int pageIndex;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  const SystemAdminPlanPage({
    required this.items,
    required this.pageIndex,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });
}

class UpsertSystemAdminSubscriptionPlan {
  final String name;
  final double price;
  final int durationDays;
  final int maxStores;
  final int maxUsers;
  final List<String> features;
  final bool isActive;

  const UpsertSystemAdminSubscriptionPlan({
    required this.name,
    required this.price,
    required this.durationDays,
    required this.maxStores,
    required this.maxUsers,
    required this.features,
    required this.isActive,
  });
}
