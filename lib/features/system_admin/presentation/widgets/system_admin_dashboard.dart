import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../subscription/domain/entities/service_package.dart';
import '../../domain/entities/system_admin_dashboard.dart';
import '../controllers/system_admin_dashboard_block_state.dart';
import '../providers/system_admin_dashboard_providers.dart';

class SystemAdminDashboard extends ConsumerWidget {
  const SystemAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OverviewBlock(),
        const SizedBox(height: AppConstants.spacingLg),
        const _ChartGrid(),
        const SizedBox(height: AppConstants.spacingLg),
        const _PaymentsBlock(),
      ],
    );
  }
}

class _OverviewBlock extends ConsumerWidget {
  const _OverviewBlock();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(systemAdminOverviewProvider);
    final notifier = ref.read(systemAdminOverviewProvider.notifier);
    return _BlockBody<DashboardOverview>(
      state: state,
      onRetry: notifier.load,
      child: (data) => _OverviewGrid(overview: data),
    );
  }
}

class _PaymentsBlock extends ConsumerWidget {
  const _PaymentsBlock();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(systemAdminPaymentsProvider);
    final notifier = ref.read(systemAdminPaymentsProvider.notifier);
    final plans =
        ref.watch(systemAdminDashboardPlansProvider).valueOrNull ??
        const <ServicePackage>[];
    if (state.data == null) {
      return _PaymentBlockState(
        status: state.status,
        message: state.errorMessage,
        onRetry: notifier.load,
      );
    }
    final data = state.data!;
    return Column(
      children: [
        Stack(
          children: [
            _PaymentsSection(
              payments: data.items,
              totalPayments: data.totalItems,
              pageIndex: data.pageIndex,
              pageCount: data.totalPages,
              filters: state.query,
              plans: plans,
              onDateRangeChanged: notifier.setDateRange,
              onPlanChanged: notifier.setPlan,
              onPaymentStatusChanged: notifier.setPaymentStatus,
              onPreviousPage: notifier.previousPage,
              onNextPage: notifier.nextPage,
            ),
            if (state.isRefreshing)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
        if (state.errorMessage != null)
          _InlineBlockError(
            message: state.errorMessage!,
            onRetry: notifier.load,
          ),
      ],
    );
  }
}

class _BlockBody<T> extends StatelessWidget {
  final DashboardBlockState<T> state;
  final Future<void> Function() onRetry;
  final Widget Function(T data) child;
  const _BlockBody({
    required this.state,
    required this.onRetry,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    if (state.data == null) {
      return _PaymentBlockState(
        status: state.status,
        message: state.errorMessage,
        onRetry: onRetry,
      );
    }
    return Column(
      children: [
        Stack(
          children: [
            child(state.data as T),
            if (state.isRefreshing)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
        if (state.errorMessage != null)
          _InlineBlockError(message: state.errorMessage!, onRetry: onRetry),
      ],
    );
  }
}

class _InlineBlockError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _InlineBlockError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
      const SizedBox(width: AppConstants.spacingXs),
      Expanded(child: Text(message, style: AppTextStyles.bodyXs)),
      TextButton(onPressed: onRetry, child: const Text('Thử lại')),
    ],
  );
}

class _PaymentBlockState extends StatelessWidget {
  final DashboardBlockStatus status;
  final String? message;
  final Future<void> Function() onRetry;
  const _PaymentBlockState({
    required this.status,
    required this.message,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) => _StatePanel(
    icon: status == DashboardBlockStatus.error
        ? Icons.error_outline
        : Icons.insert_chart_outlined,
    title: status == DashboardBlockStatus.error
        ? 'Không thể tải dữ liệu'
        : 'Đang tải dữ liệu',
    message: message ?? 'Vui lòng chờ trong giây lát.',
    action: status == DashboardBlockStatus.error
        ? OutlinedButton(onPressed: onRetry, child: const Text('Thử lại'))
        : null,
  );
}

class _DateRangeField extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final void Function(DateTime from, DateTime to) onChanged;

  const _DateRangeField({
    required this.from,
    required this.to,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2025),
          lastDate: DateTime(2027),
          initialDateRange: DateTimeRange(start: from, end: to),
        );
        if (range != null) onChanged(range.start, range.end);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacingSm,
            vertical: AppConstants.spacingSm,
          ),
          prefixIcon: Icon(Icons.date_range_outlined, size: 18),
          prefixIconConstraints: BoxConstraints(minWidth: 36),
        ),
        child: Text(
          '${formatter.format(from)} - ${formatter.format(to)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _ChartFilterRow extends StatelessWidget {
  final List<Widget> children;

  const _ChartFilterRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 240
            ? constraints.maxWidth
            : constraints.maxWidth >= 520
            ? 220.0
            : constraints.maxWidth;
        return Wrap(
          spacing: AppConstants.spacingSm,
          runSpacing: AppConstants.spacingSm,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _GroupByFilter extends StatelessWidget {
  final DashboardGroupBy value;
  final ValueChanged<DashboardGroupBy> onChanged;

  const _GroupByFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<DashboardGroupBy>(
      key: const Key('dashboard-group-by-filter'),
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSm,
          vertical: AppConstants.spacingSm,
        ),
      ),
      items: DashboardGroupBy.values
          .map(
            (item) =>
                DropdownMenuItem(value: item, child: Text(_groupByLabel(item))),
          )
          .toList(),
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
    );
  }
}

class _PlanFilter extends StatelessWidget {
  final int? value;
  final List<ServicePackage> plans;
  final ValueChanged<int?> onChanged;

  const _PlanFilter({
    required this.value,
    required this.plans,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      key: const Key('dashboard-plan-filter'),
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSm,
          vertical: AppConstants.spacingSm,
        ),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả gói')),
        for (final plan in plans)
          DropdownMenuItem(
            value: int.tryParse(plan.id),
            child: Text(plan.name),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _PaymentStatusFilter extends StatelessWidget {
  final DashboardPaymentStatus? value;
  final ValueChanged<DashboardPaymentStatus?> onChanged;

  const _PaymentStatusFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<DashboardPaymentStatus>(
      key: const Key('dashboard-payment-status-filter'),
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSm,
          vertical: AppConstants.spacingSm,
        ),
      ),
      items: DashboardPaymentStatus.values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(_paymentStatusLabel(item)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  final DashboardOverview overview;

  const _OverviewGrid({required this.overview});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        label: 'Doanh thu gói',
        value: _compactCurrency(overview.subscriptionRevenue),
        helper: _comparisonText(overview.revenueComparison),
        comparison: overview.revenueComparison,
        icon: Icons.payments_outlined,
        color: AppColors.chart1,
      ),
      _MetricData(
        label: 'Thanh toán thành công',
        value: _integer(overview.successfulPayments),
        helper: _comparisonText(overview.paymentsComparison),
        comparison: overview.paymentsComparison,
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      _MetricData(
        label: 'Subscription mới',
        value: _integer(overview.newSubscriptions),
        helper: 'Tạo mới trong kỳ',
        icon: Icons.add_card_outlined,
        color: AppColors.chart2,
      ),
      _MetricData(
        label: 'Subscription hoạt động',
        value: _integer(overview.activeSubscriptions),
        helper: 'Còn hiệu lực hiện tại',
        icon: Icons.autorenew_rounded,
        color: AppColors.info,
      ),
      _MetricData(
        label: 'Chủ cửa hàng mới',
        value: _integer(overview.newStoreAccounts),
        helper: _comparisonText(overview.accountsComparison),
        comparison: overview.accountsComparison,
        icon: Icons.person_add_alt_1_outlined,
        color: AppColors.chart3,
      ),
      _MetricData(
        label: 'Tổng chủ cửa hàng',
        value: _integer(overview.totalStoreAccounts),
        helper: '',
        icon: Icons.groups_outlined,
        color: AppColors.primary,
      ),
      _MetricData(
        label: 'Tăng trưởng tài khoản',
        value: '${overview.accountGrowthRate.toStringAsFixed(2)}%',
        helper: 'So với kỳ liền trước',
        comparison: overview.accountGrowthRate,
        icon: Icons.trending_up,
        color: AppColors.chart4,
      ),
      _MetricData(
        label: 'Tỷ lệ tài khoản trả phí',
        value: '${overview.paidAccountRate.toStringAsFixed(2)}%',
        helper: '',
        icon: Icons.workspace_premium_outlined,
        color: AppColors.chart5,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 720
            ? 3
            : constraints.maxWidth >= 480
            ? 2
            : 1;
        const spacing = AppConstants.spacingMd;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _MetricCard(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final String helper;
  final double? comparison;
  final IconData icon;
  final Color color;

  const _MetricData({
    required this.label,
    required this.value,
    required this.helper,
    this.comparison,
    required this.icon,
    required this.color,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricData metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final comparisonColor = switch (metric.comparison) {
      null => AppColors.textMuted,
      < 0 => AppColors.error,
      _ => AppColors.success,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: metric.color.withValues(alpha: 0.12),
                  foregroundColor: metric.color,
                  child: Icon(metric.icon),
                ),
                const Spacer(),
                if (metric.comparison != null)
                  Icon(
                    metric.comparison! < 0
                        ? Icons.south_east_rounded
                        : Icons.north_east_rounded,
                    size: 18,
                    color: comparisonColor,
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(metric.value, style: AppTextStyles.h2),
            const SizedBox(height: AppConstants.spacingXs),
            Text(metric.label, style: AppTextStyles.labelSm),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              metric.helper,
              style: AppTextStyles.bodyXs.copyWith(color: comparisonColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartGrid extends ConsumerWidget {
  const _ChartGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 980;
        final width = twoColumns
            ? (constraints.maxWidth - AppConstants.spacingMd) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppConstants.spacingMd,
          runSpacing: AppConstants.spacingMd,
          children: [
            SizedBox(width: width, child: const _RevenueBlock()),
            SizedBox(width: width, child: const _RevenueByPlanBlock()),
            SizedBox(width: width, child: const _AccountGrowthBlock()),
            SizedBox(width: width, child: const _DistributionBlock()),
          ],
        );
      },
    );
  }
}

class _RevenueBlock extends ConsumerWidget {
  const _RevenueBlock();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(systemAdminRevenueProvider);
    final notifier = ref.read(systemAdminRevenueProvider.notifier);
    return _BlockBody<List<RevenuePoint>>(
      state: state,
      onRetry: notifier.load,
      child: (data) => _RevenueChart(
        points: data,
        filters: state.query,
        onDateRangeChanged: notifier.setDateRange,
        onGroupByChanged: notifier.setGroupBy,
      ),
    );
  }
}

class _RevenueByPlanBlock extends ConsumerWidget {
  const _RevenueByPlanBlock();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(systemAdminRevenueByPlanProvider);
    final notifier = ref.read(systemAdminRevenueByPlanProvider.notifier);
    return _BlockBody<List<PlanRevenue>>(
      state: state,
      onRetry: notifier.load,
      child: (data) => _PlanRevenueChart(
        items: data,
        filters: state.query,
        onDateRangeChanged: notifier.setDateRange,
      ),
    );
  }
}

class _AccountGrowthBlock extends ConsumerWidget {
  const _AccountGrowthBlock();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(systemAdminAccountGrowthProvider);
    final notifier = ref.read(systemAdminAccountGrowthProvider.notifier);
    return _BlockBody<List<AccountGrowthPoint>>(
      state: state,
      onRetry: notifier.load,
      child: (data) => _AccountGrowthChart(
        points: data,
        filters: state.query,
        onDateRangeChanged: notifier.setDateRange,
        onGroupByChanged: notifier.setGroupBy,
      ),
    );
  }
}

class _DistributionBlock extends ConsumerWidget {
  const _DistributionBlock();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(systemAdminDistributionProvider);
    final notifier = ref.read(systemAdminDistributionProvider.notifier);
    final plans =
        ref.watch(systemAdminDashboardPlansProvider).valueOrNull ??
        const <ServicePackage>[];
    return _BlockBody<SubscriptionDistributionData>(
      state: state,
      onRetry: notifier.load,
      child: (data) => _SubscriptionDistributionChart(
        segments: data.segments,
        trialSubscriptions: data.trialSubscriptions,
        filters: state.query,
        plans: plans,
        onDateRangeChanged: notifier.setDateRange,
        onPlanChanged: notifier.setPlan,
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? filters;
  final Widget child;
  final double childHeight;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    this.filters,
    required this.child,
    this.childHeight = 260,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTextStyles.h4),
            const SizedBox(height: AppConstants.spacingXs),
            Text(subtitle, style: AppTextStyles.bodyXs),
            if (filters != null) ...[
              const SizedBox(height: AppConstants.spacingMd),
              filters!,
            ],
            const SizedBox(height: AppConstants.spacingLg),
            SizedBox(height: childHeight, child: child),
          ],
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<RevenuePoint> points;
  final DashboardFilters filters;
  final void Function(DateTime from, DateTime to) onDateRangeChanged;
  final ValueChanged<DashboardGroupBy> onGroupByChanged;

  const _RevenueChart({
    required this.points,
    required this.filters,
    required this.onDateRangeChanged,
    required this.onGroupByChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxRevenue = points.fold<double>(
      0,
      (maximum, point) => point.revenue > maximum ? point.revenue : maximum,
    );
    final chartMax = maxRevenue > 0 ? maxRevenue * 1.2 : 1.0;
    final interval = chartMax / 3;

    return _ChartCard(
      title: 'Doanh thu subscription',
      subtitle: 'Chỉ tính giao dịch Completed',
      filters: _ChartFilterRow(
        children: [
          _DateRangeField(
            from: filters.from,
            to: filters.to,
            onChanged: onDateRangeChanged,
          ),
          _GroupByFilter(value: filters.groupBy, onChanged: onGroupByChanged),
        ],
      ),
      child: _TimeSeriesChartViewport(
        key: const Key('revenue-day-chart-viewport'),
        scrollKey: const Key('revenue-day-chart-scroll'),
        enabled: filters.groupBy == DashboardGroupBy.day,
        pointCount: points.length,
        fixedAxis: _FixedYAxis(
          values: [chartMax, interval * 2, interval, 0],
          labelBuilder: (value) => '${(value / 1000000).toStringAsFixed(1)}M',
        ),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: chartMax,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: AppColors.border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: filters.groupBy == DashboardGroupBy.day
                  ? const AxisTitles(sideTitles: SideTitles(showTitles: false))
                  : AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: interval,
                        getTitlesWidget: (value, meta) => Text(
                          '${(value / 1000000).toStringAsFixed(1)}M',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: filters.groupBy == DashboardGroupBy.day ? 1 : 2,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(
                        top: AppConstants.spacingSm,
                      ),
                      child: Text(
                        DateFormat('dd/MM').format(points[index].period),
                        style: AppTextStyles.caption,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.textPrimary,
                getTooltipItems: (spots) => spots.map((spot) {
                  final point = points[spot.x.toInt()];
                  return LineTooltipItem(
                    '${_currency(point.revenue)}\n'
                    '${point.successfulPayments} giao dịch • '
                    '${point.newSubscriptions} subscription mới',
                    AppTextStyles.bodyXs.copyWith(color: AppColors.surface),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var index = 0; index < points.length; index++)
                    FlSpot(index.toDouble(), points[index].revenue.toDouble()),
                ],
                isCurved: true,
                color: AppColors.chart1,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.chart1.withValues(alpha: 0.28),
                      AppColors.chart1.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanRevenueChart extends StatelessWidget {
  final List<PlanRevenue> items;
  final DashboardFilters filters;
  final void Function(DateTime from, DateTime to) onDateRangeChanged;

  const _PlanRevenueChart({
    required this.items,
    required this.filters,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Doanh thu theo gói',
      subtitle: 'Số liệu là thanh toán thành công',
      filters: _ChartFilterRow(
        children: [
          _DateRangeField(
            from: filters.from,
            to: filters.to,
            onChanged: onDateRangeChanged,
          ),
        ],
      ),
      childHeight: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _PlanRevenueBar(
              item: items[index],
              color: [
                AppColors.chart1,
                AppColors.chart2,
                AppColors.chart3,
              ][index],
            ),
            if (index != items.length - 1)
              const SizedBox(height: AppConstants.spacingMd),
          ],
        ],
      ),
    );
  }
}

class _PlanRevenueBar extends StatelessWidget {
  final PlanRevenue item;
  final Color color;

  const _PlanRevenueBar({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(item.planName, style: AppTextStyles.labelSm)),
            Text(
              '${_compactCurrency(item.revenue)} • '
              '${item.successfulPayments} giao dịch',
              style: AppTextStyles.bodyXs,
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingSm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: LinearProgressIndicator(
            minHeight: 14,
            value: item.revenuePercentage / 100,
            backgroundColor: AppColors.muted,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: AppConstants.spacingXs),
        Text(
          '${item.revenuePercentage.toStringAsFixed(2)}%',
          textAlign: TextAlign.end,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class _AccountGrowthChart extends StatelessWidget {
  final List<AccountGrowthPoint> points;
  final DashboardFilters filters;
  final void Function(DateTime from, DateTime to) onDateRangeChanged;
  final ValueChanged<DashboardGroupBy> onGroupByChanged;

  const _AccountGrowthChart({
    required this.points,
    required this.filters,
    required this.onDateRangeChanged,
    required this.onGroupByChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxNew = points
        .fold<int>(
          0,
          (maximum, point) => point.newStoreAccounts > maximum
              ? point.newStoreAccounts
              : maximum,
        )
        .toDouble();
    final chartMax = maxNew > 0 ? maxNew * 1.25 : 1.0;
    final minTotal = points.isEmpty
        ? 0
        : points
              .map((point) => point.totalStoreAccounts)
              .reduce((a, b) => a < b ? a : b);
    final maxTotal = points.isEmpty
        ? 0
        : points
              .map((point) => point.totalStoreAccounts)
              .reduce((a, b) => a > b ? a : b);

    double normalizedTotal(int total) {
      if (maxTotal == minTotal) return chartMax / 2;
      return ((total - minTotal) / (maxTotal - minTotal)) * chartMax;
    }

    return _ChartCard(
      title: 'Tăng trưởng tài khoản',
      subtitle: 'Cột: tài khoản mới • Đường: tổng tài khoản tích lũy',
      filters: _ChartFilterRow(
        children: [
          _DateRangeField(
            from: filters.from,
            to: filters.to,
            onChanged: onDateRangeChanged,
          ),
          _GroupByFilter(value: filters.groupBy, onChanged: onGroupByChanged),
        ],
      ),
      child: _TimeSeriesChartViewport(
        key: const Key('account-growth-day-chart-viewport'),
        scrollKey: const Key('account-growth-day-chart-scroll'),
        enabled: filters.groupBy == DashboardGroupBy.day,
        pointCount: points.length,
        fixedAxis: _FixedYAxis(
          values: [chartMax, chartMax * 2 / 3, chartMax / 3, 0],
          labelBuilder: (value) => value.toStringAsFixed(0),
        ),
        child: Stack(
          children: [
            BarChart(
              BarChartData(
                minY: 0,
                maxY: chartMax,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: filters.groupBy == DashboardGroupBy.day
                      ? const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        )
                      : const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                          ),
                        ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if ((filters.groupBy != DashboardGroupBy.day &&
                                index.isOdd) ||
                            index < 0 ||
                            index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: AppConstants.spacingSm,
                          ),
                          child: Text(
                            DateFormat('dd/MM').format(points[index].period),
                            style: AppTextStyles.caption,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var index = 0; index < points.length; index++)
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: points[index].newStoreAccounts.toDouble(),
                          width: 12,
                          color: AppColors.chart2.withValues(alpha: 0.72),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppTheme.radiusSm),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            IgnorePointer(
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: chartMax,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var index = 0; index < points.length; index++)
                          FlSpot(
                            index.toDouble(),
                            normalizedTotal(points[index].totalStoreAccounts),
                          ),
                      ],
                      isCurved: true,
                      color: AppColors.chart3,
                      barWidth: 3,
                      dotData: FlDotData(
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 3,
                              color: AppColors.chart3,
                              strokeWidth: 0,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSeriesChartViewport extends StatefulWidget {
  static const _bucketWidth = 64.0;

  final bool enabled;
  final int pointCount;
  final Key scrollKey;
  final Widget? fixedAxis;
  final Widget child;

  const _TimeSeriesChartViewport({
    super.key,
    required this.enabled,
    required this.pointCount,
    required this.scrollKey,
    this.fixedAxis,
    required this.child,
  });

  @override
  State<_TimeSeriesChartViewport> createState() =>
      _TimeSeriesChartViewportState();
}

class _TimeSeriesChartViewportState extends State<_TimeSeriesChartViewport> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _scrollToLatest();
  }

  @override
  void didUpdateWidget(covariant _TimeSeriesChartViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled &&
        (!oldWidget.enabled || oldWidget.pointCount != widget.pointCount)) {
      _scrollToLatest();
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.enabled || !_controller.hasClients) return;
      _controller.jumpTo(_controller.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = math.max(
          constraints.maxWidth,
          widget.pointCount * _TimeSeriesChartViewport._bucketWidth + 48,
        );
        final scrollableChart = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: AppConstants.spacingXs),
              child: Text(
                'Kéo ngang để xem thêm ngày',
                style: AppTextStyles.caption,
              ),
            ),
            Expanded(
              child: Scrollbar(
                controller: _controller,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  key: widget.scrollKey,
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: contentWidth, child: widget.child),
                ),
              ),
            ),
          ],
        );
        if (widget.fixedAxis == null) return scrollableChart;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 42, child: widget.fixedAxis),
            const SizedBox(width: AppConstants.spacingXs),
            Expanded(child: scrollableChart),
          ],
        );
      },
    );
  }
}

class _FixedYAxis extends StatelessWidget {
  final List<double> values;
  final String Function(double value) labelBuilder;

  const _FixedYAxis({required this.values, required this.labelBuilder});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppConstants.spacingLg, bottom: 28),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final value in values)
          Text(labelBuilder(value), style: AppTextStyles.caption),
      ],
    ),
  );
}

class _SubscriptionDistributionChart extends StatelessWidget {
  final List<SubscriptionSegment> segments;
  final int trialSubscriptions;
  final DashboardFilters filters;
  final List<ServicePackage> plans;
  final void Function(DateTime from, DateTime to) onDateRangeChanged;
  final ValueChanged<int?> onPlanChanged;

  const _SubscriptionDistributionChart({
    required this.segments,
    required this.trialSubscriptions,
    required this.filters,
    required this.plans,
    required this.onDateRangeChanged,
    required this.onPlanChanged,
  });

  @override
  Widget build(BuildContext context) {
    const colors = [
      AppColors.chart2,
      AppColors.chart4,
      AppColors.chart3,
      AppColors.error,
    ];
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.count);

    return _ChartCard(
      title: 'Phân bổ subscription',
      subtitle: 'Trial là thuộc tính riêng, không phải trạng thái',
      filters: _ChartFilterRow(
        children: [
          _DateRangeField(
            from: filters.from,
            to: filters.to,
            onChanged: onDateRangeChanged,
          ),
          _PlanFilter(
            value: filters.planId,
            plans: plans,
            onChanged: onPlanChanged,
          ),
        ],
      ),
      childHeight: 400,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final chart = SizedBox(
            width: compact ? 150 : 190,
            height: compact ? 150 : 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: compact ? 42 : 55,
                    sectionsSpace: 3,
                    sections: [
                      for (var index = 0; index < segments.length; index++)
                        PieChartSectionData(
                          value: segments[index].count.toDouble(),
                          color: colors[index],
                          radius: compact ? 28 : 36,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_integer(total), style: AppTextStyles.h3),
                    Text('tổng số', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          );
          final legend = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < segments.length; index++)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppConstants.spacingSm,
                  ),
                  child: _LegendRow(
                    color: colors[index],
                    label: segments[index].label,
                    value:
                        '${segments[index].count} (${segments[index].percentage.toStringAsFixed(1)}%)',
                  ),
                ),
              const Divider(),
              _LegendRow(
                color: AppColors.primary,
                label: 'Đang dùng thử',
                value: '$trialSubscriptions',
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [
                chart,
                const SizedBox(height: AppConstants.spacingSm),
                Expanded(child: legend),
              ],
            );
          }
          return Row(
            children: [
              chart,
              const SizedBox(width: AppConstants.spacingLg),
              Expanded(child: legend),
            ],
          );
        },
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyXs,
          ),
        ),
        Text(value, style: AppTextStyles.labelXs),
      ],
    );
  }
}

class _PaymentsSection extends StatelessWidget {
  final List<SubscriptionPaymentItem> payments;
  final int totalPayments;
  final int pageIndex;
  final int pageCount;
  final DashboardFilters filters;
  final List<ServicePackage> plans;
  final void Function(DateTime from, DateTime to) onDateRangeChanged;
  final ValueChanged<int?> onPlanChanged;
  final ValueChanged<DashboardPaymentStatus?> onPaymentStatusChanged;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  const _PaymentsSection({
    required this.payments,
    required this.totalPayments,
    required this.pageIndex,
    required this.pageCount,
    required this.filters,
    required this.plans,
    required this.onDateRangeChanged,
    required this.onPlanChanged,
    required this.onPaymentStatusChanged,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thanh toán subscription', style: AppTextStyles.h4),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        '$totalPayments giao dịch phù hợp bộ lọc',
                        style: AppTextStyles.bodyXs,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            _ChartFilterRow(
              children: [
                _DateRangeField(
                  from: filters.from,
                  to: filters.to,
                  onChanged: onDateRangeChanged,
                ),
                _PlanFilter(
                  value: filters.planId,
                  plans: plans,
                  onChanged: onPlanChanged,
                ),
                _PaymentStatusFilter(
                  value: filters.paymentStatus,
                  onChanged: onPaymentStatusChanged,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            if (payments.isEmpty)
              const _InlineEmpty()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 760) {
                    return Column(
                      key: const Key('payments-mobile-list'),
                      children: [
                        for (final payment in payments)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppConstants.spacingSm,
                            ),
                            child: _PaymentCard(payment: payment),
                          ),
                      ],
                    );
                  }
                  return _PaymentsTable(payments: payments);
                },
              ),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Trang $pageIndex/$pageCount',
                  style: AppTextStyles.bodyXs,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                IconButton(
                  key: const Key('payments-previous-page'),
                  tooltip: 'Trang trước',
                  onPressed: pageIndex > 1 ? onPreviousPage : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  key: const Key('payments-next-page'),
                  tooltip: 'Trang sau',
                  onPressed: pageIndex < pageCount ? onNextPage : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentsTable extends StatelessWidget {
  final List<SubscriptionPaymentItem> payments;

  const _PaymentsTable({required this.payments});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('payments-desktop-table'),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: AppTextStyles.labelXs,
        dataTextStyle: AppTextStyles.bodyXs,
        columns: const [
          DataColumn(label: Text('Payment ID')),
          DataColumn(label: Text('Chủ cửa hàng')),
          DataColumn(label: Text('Gói')),
          DataColumn(label: Text('Số tiền')),
          DataColumn(label: Text('Phương thức')),
          DataColumn(label: Text('Trạng thái')),
          DataColumn(label: Text('Ngày thanh toán')),
          DataColumn(label: Text('Ngày tạo')),
        ],
        rows: [
          for (final payment in payments)
            DataRow(
              cells: [
                DataCell(Text('#${payment.paymentId}')),
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelXs,
                        ),
                        Text(
                          payment.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(Text(payment.planName)),
                DataCell(Text(_currency(payment.amount))),
                DataCell(Text(payment.paymentMethod)),
                DataCell(_PaymentStatusChip(status: payment.status)),
                DataCell(Text(_dateTime(payment.paidAt))),
                DataCell(Text(_dateTime(payment.createdAt))),
              ],
            ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final SubscriptionPaymentItem payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${payment.paymentId} • ${payment.planName}',
                  style: AppTextStyles.labelSm,
                ),
              ),
              _PaymentStatusChip(status: payment.status),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(payment.ownerName, style: AppTextStyles.bodySm),
          Text(payment.email, style: AppTextStyles.bodyXs),
          const Divider(height: AppConstants.spacingLg),
          _KeyValue(label: 'Số tiền', value: _currency(payment.amount)),
          _KeyValue(label: 'Phương thức', value: payment.paymentMethod),
          _KeyValue(label: 'Ngày thanh toán', value: _dateTime(payment.paidAt)),
          _KeyValue(label: 'Ngày tạo', value: _dateTime(payment.createdAt)),
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingXs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyXs)),
          Text(value, style: AppTextStyles.labelXs),
        ],
      ),
    );
  }
}

class _PaymentStatusChip extends StatelessWidget {
  final DashboardPaymentStatus status;

  const _PaymentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      DashboardPaymentStatus.completed => AppColors.success,
      DashboardPaymentStatus.pending => AppColors.warning,
      DashboardPaymentStatus.failed => AppColors.error,
      DashboardPaymentStatus.refunded => AppColors.info,
      DashboardPaymentStatus.all => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Text(
        _paymentStatusLabel(status),
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppConstants.spacingMd),
            Text(title, style: AppTextStyles.h3),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm,
            ),
            if (action != null) ...[
              const SizedBox(height: AppConstants.spacingLg),
              SizedBox(width: 180, child: action),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppConstants.spacingXl),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: AppColors.textMuted),
          SizedBox(height: AppConstants.spacingSm),
          Text('Không có giao dịch phù hợp'),
        ],
      ),
    );
  }
}

String _groupByLabel(DashboardGroupBy value) => switch (value) {
  DashboardGroupBy.day => 'Theo ngày',
  DashboardGroupBy.week => 'Theo tuần',
  DashboardGroupBy.month => 'Theo tháng',
};

String _paymentStatusLabel(DashboardPaymentStatus value) => switch (value) {
  DashboardPaymentStatus.all => 'Tất cả trạng thái',
  DashboardPaymentStatus.pending => 'Chờ thanh toán',
  DashboardPaymentStatus.completed => 'Hoàn thành',
  DashboardPaymentStatus.failed => 'Thất bại',
  DashboardPaymentStatus.refunded => 'Đã hoàn tiền',
};

String _comparisonText(double value) {
  final prefix = value >= 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(1)}% so với kỳ trước';
}

String _compactCurrency(num value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(2)}M ₫';
  }
  return _currency(value);
}

String _currency(num value) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);

String _integer(int value) =>
    NumberFormat.decimalPattern('vi_VN').format(value);

String _dateTime(DateTime? value) {
  if (value == null) return '—';
  return DateFormat('HH:mm dd/MM/yyyy').format(value.toLocal());
}
