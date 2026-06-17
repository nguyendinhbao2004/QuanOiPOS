import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/owner_dashboard/data/models/owner_dashboard_insight_model.dart';
import 'package:quan_oi/features/store_operations/owner_dashboard/data/models/owner_dashboard_request_model.dart';
import 'package:quan_oi/features/store_operations/owner_dashboard/domain/entities/owner_dashboard_insight.dart';
import 'package:quan_oi/features/store_operations/owner_dashboard/domain/entities/owner_dashboard_insight_type.dart';
import 'package:quan_oi/features/store_operations/owner_dashboard/domain/entities/owner_dashboard_metrics.dart';
import 'package:quan_oi/features/store_operations/owner_dashboard/domain/entities/owner_dashboard_period.dart';
import 'package:quan_oi/features/store_operations/owner_dashboard/domain/repositories/owner_dashboard_repository.dart';
import 'package:quan_oi/features/store_operations/owner_dashboard/domain/usecases/load_owner_dashboard_insight_use_case.dart';
import 'package:quan_oi/features/store_operations/owner_dashboard/presentation/controllers/owner_dashboard_state.dart';
import 'package:quan_oi/features/store_operations/owner_dashboard/presentation/providers/owner_dashboard_providers.dart';

void main() {
  group('OwnerDashboardPeriod', () {
    test('builds day range from local anchor', () {
      final period = OwnerDashboardPeriod.from(
        type: OwnerDashboardPeriodType.day,
        anchorDate: DateTime(2026, 6, 17, 15, 30),
      );

      expect(period.fromDate, DateTime(2026, 6, 17));
      expect(period.toDate, DateTime(2026, 6, 17, 23, 59, 59, 999));
    });

    test('builds week range from Monday to Sunday', () {
      final period = OwnerDashboardPeriod.from(
        type: OwnerDashboardPeriodType.week,
        anchorDate: DateTime(2026, 6, 17),
      );

      expect(period.fromDate, DateTime(2026, 6, 15));
      expect(period.toDate, DateTime(2026, 6, 21, 23, 59, 59, 999));
    });

    test('builds month range to end of month', () {
      final period = OwnerDashboardPeriod.from(
        type: OwnerDashboardPeriodType.month,
        anchorDate: DateTime(2026, 2, 17),
      );

      expect(period.fromDate, DateTime(2026, 2));
      expect(period.toDate, DateTime(2026, 2, 28, 23, 59, 59, 999));
    });
  });

  test('request model serializes store, date range and type', () {
    final request = OwnerDashboardRequestModel.fromPeriod(
      storeId: 5,
      period: OwnerDashboardPeriod.from(
        type: OwnerDashboardPeriodType.day,
        anchorDate: DateTime(2026, 6, 17),
      ),
      type: OwnerDashboardInsightType.suggestion,
    );

    expect(request.toJson()['storeId'], 5);
    expect(request.toJson()['type'], 2);
    expect(
      request.toJson()['fromDate'],
      DateTime(2026, 6, 17).toUtc().toIso8601String(),
    );
    expect(
      request.toJson()['toDate'],
      DateTime(2026, 6, 17, 23, 59, 59, 999).toUtc().toIso8601String(),
    );
  });

  test('response model maps metrics and top products', () {
    final model = OwnerDashboardInsightModel.fromJson({
      'id': 12,
      'storeId': 5,
      'type': 1,
      'fromDate': '2026-06-01T00:00:00Z',
      'toDate': '2026-06-17T23:59:59Z',
      'content': 'Doanh thu tăng tốt.',
      'metrics': {
        'totalRevenue': 1500000,
        'paidRevenue': 1450000,
        'completedOrderCount': 35,
        'cancelledOrderCount': 3,
        'averageOrderValue': 42857.14,
        'topProducts': [
          {
            'productId': 5,
            'productName': 'Trà sữa truyền thống',
            'orderItemCount': 20,
          },
        ],
      },
      'createdAt': '2026-06-17T15:00:00Z',
    });

    final entity = model.toEntity();

    expect(entity.id, 12);
    expect(entity.metrics.totalRevenue, 1500000);
    expect(entity.metrics.completedOrderCount, 35);
    expect(
      entity.metrics.topProducts.single.productName,
      'Trà sữa truyền thống',
    );
  });

  test('notifier loads success and reloads when type changes', () async {
    final repository = _FakeOwnerDashboardRepository();
    final container = ProviderContainer(
      overrides: [
        loadOwnerDashboardInsightUseCaseProvider.overrideWithValue(
          LoadOwnerDashboardInsightUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final provider = ownerDashboardNotifierProvider(5);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(provider).status, OwnerDashboardStatus.ready);
    expect(container.read(provider).insight?.storeId, 5);
    expect(repository.calls, 1);

    await container
        .read(provider.notifier)
        .changeInsightType(OwnerDashboardInsightType.suggestion);

    expect(container.read(provider).status, OwnerDashboardStatus.ready);
    expect(container.read(provider).type, OwnerDashboardInsightType.suggestion);
    expect(repository.calls, 2);
  });

  test('notifier exposes API error for retry UI', () async {
    final container = ProviderContainer(
      overrides: [
        loadOwnerDashboardInsightUseCaseProvider.overrideWithValue(
          LoadOwnerDashboardInsightUseCase(
            _FakeOwnerDashboardRepository(error: Exception('API failed')),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final provider = ownerDashboardNotifierProvider(5);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(provider).status, OwnerDashboardStatus.error);
    expect(container.read(provider).errorMessage, 'API failed');
  });
}

class _FakeOwnerDashboardRepository implements OwnerDashboardRepository {
  final Exception? error;
  int calls = 0;

  _FakeOwnerDashboardRepository({this.error});

  @override
  Future<OwnerDashboardInsight> loadSalesInsight({
    required int storeId,
    required OwnerDashboardPeriod period,
    required OwnerDashboardInsightType type,
  }) async {
    calls += 1;
    final failure = error;
    if (failure != null) {
      throw failure;
    }

    return OwnerDashboardInsight(
      id: calls,
      storeId: storeId,
      type: type,
      fromDate: period.fromDate,
      toDate: period.toDate,
      content: 'Insight $calls',
      metrics: const OwnerDashboardMetrics(
        totalRevenue: 100000,
        paidRevenue: 90000,
        completedOrderCount: 4,
        cancelledOrderCount: 1,
        averageOrderValue: 25000,
        topProducts: [],
      ),
      createdAt: DateTime(2026, 6, 17),
    );
  }
}
