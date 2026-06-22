import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/system_admin/package_management/data/models/system_admin_subscription_plan_models.dart';

void main() {
  group('SystemAdminPlanSummaryModel', () {
    test('maps dynamic plan usage from the summary contract', () {
      final summary = SystemAdminPlanSummaryModel.fromJson({
        'totalPlans': 6,
        'activePlans': 4,
        'inactivePlans': 2,
        'planUsage': [
          {'planId': 2, 'planName': 'Basic', 'activeStoreCount': 214},
        ],
      }).toEntity();

      expect(summary.totalPlans, 6);
      expect(summary.inactivePlans, 2);
      expect(summary.planUsage.single.planName, 'Basic');
      expect(summary.planUsage.single.activeStoreCount, 214);
    });
  });

  group('SystemAdminPlanPageModel', () {
    test('parses feature JSON and pagination', () {
      final page = SystemAdminPlanPageModel.fromJson({
        'items': [
          {
            'id': 2,
            'name': 'Basic',
            'price': 199000,
            'durationDays': 30,
            'maxStores': 1,
            'maxUsers': 5,
            'features': '["Báo cáo cơ bản"]',
            'isActive': true,
            'createdAt': '2026-06-01T00:00:00Z',
            'updatedAt': null,
          },
        ],
        'pagination': {
          'pageIndex': 1,
          'pageSize': 10,
          'totalItems': 1,
          'totalPages': 1,
        },
      }).toEntity();

      expect(page.items.single.id, 2);
      expect(page.items.single.features, ['Báo cáo cơ bản']);
      expect(page.items.single.isActive, isTrue);
      expect(page.totalItems, 1);
    });
  });
}
