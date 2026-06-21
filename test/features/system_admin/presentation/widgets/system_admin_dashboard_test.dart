import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/theme/app_theme.dart';
import 'package:quan_oi/features/subscription/domain/entities/service_package.dart';
import 'package:quan_oi/features/system_admin/domain/entities/system_admin_dashboard.dart';
import 'package:quan_oi/features/system_admin/presentation/controllers/system_admin_dashboard_block_notifiers.dart';
import 'package:quan_oi/features/system_admin/presentation/controllers/system_admin_dashboard_block_state.dart';
import 'package:quan_oi/features/system_admin/presentation/providers/system_admin_dashboard_providers.dart';
import 'package:quan_oi/features/system_admin/presentation/widgets/system_admin_dashboard.dart';

void main() {
  testWidgets('renders independently loaded dashboard blocks on desktop', (
    tester,
  ) async {
    await _pumpDashboard(tester, const Size(1280, 900));
    expect(find.text('Doanh thu gói'), findsOneWidget);
    expect(find.text('Doanh thu subscription'), findsOneWidget);
    expect(find.byKey(const Key('payments-desktop-table')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders payment cards on mobile', (tester) async {
    await _pumpDashboard(tester, const Size(390, 844));
    expect(find.byKey(const Key('payments-mobile-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolls long daily time series without overflow', (
    tester,
  ) async {
    await _pumpDashboard(tester, const Size(390, 844));
    final scrollable = find.byKey(const Key('revenue-day-chart-scroll'));
    expect(scrollable, findsOneWidget);
    await tester.ensureVisible(scrollable);
    await tester.pump();
    await tester.drag(scrollable, const Offset(-240, 0));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDashboard(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        systemAdminOverviewProvider.overrideWith(() => _OverviewTestNotifier()),
        systemAdminRevenueProvider.overrideWith(() => _RevenueTestNotifier()),
        systemAdminRevenueByPlanProvider.overrideWith(
          () => _PlanTestNotifier(),
        ),
        systemAdminAccountGrowthProvider.overrideWith(
          () => _GrowthTestNotifier(),
        ),
        systemAdminDistributionProvider.overrideWith(
          () => _DistributionTestNotifier(),
        ),
        systemAdminPaymentsProvider.overrideWith(() => _PaymentsTestNotifier()),
        systemAdminDashboardPlansProvider.overrideWith(
          (ref) async => const [
            ServicePackage(
              id: '1',
              name: 'Basic',
              priceAmount: 149000,
              durationDays: 30,
              maxStores: 1,
              maxUsers: 5,
              features: [],
              isActive: true,
            ),
          ],
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: SystemAdminDashboard(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

final _query = SystemAdminDashboardQuery(
  from: DateTime.utc(2026, 6, 1),
  to: DateTime.utc(2026, 6, 1),
  groupBy: DashboardGroupBy.day,
  paymentStatus: DashboardPaymentStatus.all,
);

class _OverviewTestNotifier extends OverviewNotifier {
  _OverviewTestNotifier() : super((_) async => _overview);
  @override
  DashboardBlockState<DashboardOverview> build() => DashboardBlockState(
    status: DashboardBlockStatus.ready,
    query: _query,
    data: _overview,
  );
}

class _RevenueTestNotifier extends RevenueNotifier {
  _RevenueTestNotifier() : super((_) async => _revenue);
  @override
  DashboardBlockState<List<RevenuePoint>> build() => DashboardBlockState(
    status: DashboardBlockStatus.ready,
    query: _query,
    data: _revenue,
  );
}

class _PlanTestNotifier extends RevenueByPlanNotifier {
  _PlanTestNotifier() : super((_) async => _plans);
  @override
  DashboardBlockState<List<PlanRevenue>> build() => DashboardBlockState(
    status: DashboardBlockStatus.ready,
    query: _query,
    data: _plans,
  );
}

class _GrowthTestNotifier extends AccountGrowthNotifier {
  _GrowthTestNotifier() : super((_) async => _growth);
  @override
  DashboardBlockState<List<AccountGrowthPoint>> build() => DashboardBlockState(
    status: DashboardBlockStatus.ready,
    query: _query,
    data: _growth,
  );
}

class _DistributionTestNotifier extends DistributionNotifier {
  _DistributionTestNotifier() : super((_) async => _distribution);
  @override
  DashboardBlockState<SubscriptionDistributionData> build() =>
      DashboardBlockState(
        status: DashboardBlockStatus.ready,
        query: _query,
        data: _distribution,
      );
}

class _PaymentsTestNotifier extends PaymentsNotifier {
  _PaymentsTestNotifier()
    : super((_, {required pageIndex, required pageSize}) async => _payments);
  @override
  DashboardPaymentsState build() => DashboardPaymentsState(
    status: DashboardBlockStatus.ready,
    query: _query,
    data: _payments,
  );
}

const _overview = DashboardOverview(
  subscriptionRevenue: 0,
  successfulPayments: 0,
  newSubscriptions: 0,
  activeSubscriptions: 0,
  newStoreAccounts: 0,
  totalStoreAccounts: 1,
  accountGrowthRate: 0,
  paidAccountRate: 0,
  revenueComparison: 0,
  paymentsComparison: 0,
  accountsComparison: 0,
);
final _revenue = List.generate(
  31,
  (index) => RevenuePoint(
    period: DateTime.utc(2026, 6, index + 1),
    revenue: 0,
    successfulPayments: 0,
    newSubscriptions: 0,
  ),
);
const _plans = [
  PlanRevenue(
    planId: 1,
    planName: 'Basic',
    revenue: 0,
    successfulPayments: 0,
    revenuePercentage: 0,
  ),
];
final _growth = List.generate(
  31,
  (index) => AccountGrowthPoint(
    period: DateTime.utc(2026, 6, index + 1),
    newStoreAccounts: 0,
    totalStoreAccounts: 1,
  ),
);
const _distribution = SubscriptionDistributionData(
  segments: [
    SubscriptionSegment(
      status: 'ACTIVE',
      label: 'Đang hoạt động',
      count: 1,
      percentage: 100,
    ),
  ],
  trialSubscriptions: 0,
);
final _payments = SubscriptionPaymentPage(
  items: [
    SubscriptionPaymentItem(
      paymentId: 1,
      subscriptionId: 1,
      accountId: 1,
      planId: 1,
      ownerName: 'A',
      email: 'a@example.com',
      planName: 'Basic',
      amount: 149000,
      currency: 'VND',
      paymentMethod: 'PayOS',
      status: DashboardPaymentStatus.completed,
      paidAt: DateTime.utc(2026, 6, 1),
      createdAt: DateTime.utc(2026, 6, 1),
    ),
  ],
  pageIndex: 1,
  pageSize: 10,
  totalItems: 1,
  totalPages: 1,
);
