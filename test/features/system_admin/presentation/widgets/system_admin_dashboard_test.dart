import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/theme/app_theme.dart';
import 'package:quan_oi/features/system_admin/presentation/mock/system_admin_dashboard_mock_data.dart';
import 'package:quan_oi/features/system_admin/presentation/providers/system_admin_dashboard_mock_provider.dart';
import 'package:quan_oi/features/system_admin/presentation/widgets/system_admin_dashboard.dart';

void main() {
  testWidgets('renders full dashboard on desktop', (tester) async {
    await _pumpDashboard(tester, const Size(1280, 900));

    expect(find.text('Bộ lọc báo cáo'), findsNothing);
    expect(find.text('Doanh thu gói'), findsOneWidget);
    expect(find.text('Tỷ lệ tài khoản trả phí'), findsOneWidget);
    expect(find.text('Doanh thu subscription'), findsOneWidget);
    expect(find.text('Doanh thu theo gói'), findsOneWidget);
    expect(find.text('Tăng trưởng tài khoản'), findsWidgets);
    expect(find.text('Phân bổ subscription'), findsOneWidget);
    expect(find.byKey(const Key('payments-desktop-table')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses payment cards on mobile without overflow', (tester) async {
    await _pumpDashboard(tester, const Size(390, 844));

    expect(find.byKey(const Key('payments-mobile-list')), findsOneWidget);
    expect(find.byKey(const Key('payments-desktop-table')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders empty and error states', (tester) async {
    final baseState = _readyState();
    await _pumpDashboard(
      tester,
      const Size(800, 800),
      state: baseState.copyWith(status: DashboardLoadStatus.empty),
    );
    expect(find.text('Chưa có dữ liệu dashboard'), findsOneWidget);

    await _pumpDashboard(
      tester,
      const Size(800, 800),
      state: baseState.copyWith(status: DashboardLoadStatus.error),
    );
    expect(find.text('Không thể tải dashboard'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    expect(find.text('Doanh thu gói'), findsOneWidget);
  });

  test('mock notifier filters payments and paginates locally', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(systemAdminDashboardMockProvider.notifier);

    notifier.setPlan(2);
    notifier.setPaymentStatus(DashboardPaymentStatus.completed);
    var state = container.read(systemAdminDashboardMockProvider);

    expect(
      state.filteredPayments.every(
        (payment) =>
            payment.planId == 2 &&
            payment.status == DashboardPaymentStatus.completed,
      ),
      isTrue,
    );

    notifier.setPlan(null);
    notifier.setPaymentStatus(DashboardPaymentStatus.all);
    state = container.read(systemAdminDashboardMockProvider);
    expect(state.pageCount, greaterThan(1));

    notifier.nextPage();
    expect(container.read(systemAdminDashboardMockProvider).pageIndex, 1);
    notifier.previousPage();
    expect(container.read(systemAdminDashboardMockProvider).pageIndex, 0);

    notifier.setGroupBy(DashboardGroupBy.week);
    expect(
      container.read(systemAdminDashboardMockProvider).filters.groupBy,
      DashboardGroupBy.week,
    );
  });
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  Size size, {
  SystemAdminDashboardState? state,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        if (state != null)
          systemAdminDashboardMockProvider.overrideWith(
            () => _DashboardTestNotifier(state),
          ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SystemAdminDashboard(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

SystemAdminDashboardState _readyState() {
  return SystemAdminDashboardState(
    status: DashboardLoadStatus.ready,
    filters: DashboardFilters(
      from: DateTime(2026, 6),
      to: DateTime(2026, 6, 11),
      groupBy: DashboardGroupBy.day,
      planId: null,
      paymentStatus: DashboardPaymentStatus.all,
    ),
    data: SystemAdminDashboardMockData.data,
  );
}

class _DashboardTestNotifier extends SystemAdminDashboardMockNotifier {
  final SystemAdminDashboardState initialState;

  _DashboardTestNotifier(this.initialState);

  @override
  SystemAdminDashboardState build() => initialState;
}
