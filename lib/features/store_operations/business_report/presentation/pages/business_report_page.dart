import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../config/router_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/domain/entities/store.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../domain/entities/business_report.dart';
import '../controllers/business_report_notifier.dart';
import '../controllers/business_report_state.dart';
import '../providers/business_report_providers.dart';

class BusinessReportPage extends ConsumerWidget {
  final int storeId;

  const BusinessReportPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo kinh doanh AI'),
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed(
            RouteNames.storeOverview,
            pathParameters: {'storeId': storeId.toString()},
          ),
        ),
      ),
      body: SafeArea(
        child: switch (accessState.status) {
          StoreAccessStatus.initial ||
          StoreAccessStatus.loading => const _LoadingView(),
          StoreAccessStatus.forbidden => _BlockedView(
            icon: Icons.lock_outline_rounded,
            title: 'Không có quyền truy cập',
            message:
                accessState.errorMessage ??
                'Tài khoản của bạn không có quyền truy cập cửa hàng này.',
            actionLabel: 'Về danh sách cửa hàng',
            onAction: () => context.goNamed(RouteNames.myStores),
          ),
          StoreAccessStatus.error => _BlockedView(
            icon: Icons.error_outline_rounded,
            title: 'Không thể tải thông tin cửa hàng',
            message: accessState.errorMessage ?? 'Vui lòng thử lại sau.',
            actionLabel: 'Thử lại',
            onAction: () => ref
                .read(storeAccessNotifierProvider(storeId).notifier)
                .loadAccess(),
          ),
          StoreAccessStatus.ready => _ReadyView(accessState: accessState),
        },
      ),
    );
  }
}

class _ReadyView extends ConsumerWidget {
  final StoreAccessState accessState;

  const _ReadyView({required this.accessState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessContext = accessState.context;
    if (accessContext == null) {
      return _BlockedView(
        icon: Icons.storefront_outlined,
        title: 'Chưa có dữ liệu cửa hàng',
        message: 'Vui lòng quay lại danh sách cửa hàng và thử lại.',
        actionLabel: 'Về danh sách cửa hàng',
        onAction: () => context.goNamed(RouteNames.myStores),
      );
    }

    if (!accessState.can(AppPermissionCodes.dashboardView)) {
      return _BlockedView(
        icon: Icons.visibility_off_outlined,
        title: 'Bạn chưa có quyền xem báo cáo',
        message: 'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền.',
        actionLabel: 'Về tổng quan cửa hàng',
        onAction: () => context.goNamed(
          RouteNames.storeOverview,
          pathParameters: {'storeId': accessContext.store.id.toString()},
        ),
      );
    }

    final reportState = ref.watch(
      businessReportNotifierProvider(accessContext.store.id),
    );
    final notifier = ref.read(
      businessReportNotifierProvider(accessContext.store.id).notifier,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingXxl,
      ),
      children: [
        _Header(store: accessContext.store),
        const SizedBox(height: AppConstants.spacingLg),
        _FilterPanel(
          state: reportState,
          onPickRange: () => _pickRange(context, reportState, notifier),
        ),
        if (reportState.status == BusinessReportStatus.loading) ...[
          const SizedBox(height: AppConstants.spacingMd),
          _GeneratingBanner(),
        ],
        if (reportState.status == BusinessReportStatus.error) ...[
          const SizedBox(height: AppConstants.spacingMd),
          _ErrorCard(
            message:
                reportState.errorMessage ??
                'Không thể tạo báo cáo kinh doanh AI.',
            onRetry: notifier.createReport,
          ),
        ],
        const SizedBox(height: AppConstants.spacingLg),
        if (reportState.report == null)
          _EmptyCard(onCreate: notifier.createReport)
        else
          _ReportContent(report: reportState.report!),
      ],
    );
  }

  Future<void> _pickRange(
    BuildContext context,
    BusinessReportState state,
    BusinessReportNotifier notifier,
  ) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: state.fromDate, end: state.toDate),
    );
    if (range != null) {
      notifier.changeDateRange(range.start, range.end);
    }
  }
}

class _Header extends StatelessWidget {
  final Store store;

  const _Header({required this.store});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.surface,
            size: 24,
          ),
        ),
        const SizedBox(width: AppConstants.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.storeName,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Phân tích doanh thu · Lợi nhuận · Giờ cao điểm · Tồn kho',
                style: AppTextStyles.bodyXs,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final BusinessReportState state;
  final VoidCallback onPickRange;

  const _FilterPanel({
    required this.state,
    required this.onPickRange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: state.isLoading ? null : onPickRange,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              alignment: Alignment.centerLeft,
            ),
            icon: const Icon(Icons.date_range_outlined, size: 18),
            label: Text(
              _formatRange(state.fromDate, state.toDate),
              style: AppTextStyles.labelSm,
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Text(
            'AI đang phân tích dữ liệu kinh doanh...',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  final BusinessReport report;

  const _ReportContent({required this.report});

  @override
  Widget build(BuildContext context) {
    final metrics = report.metrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (report.createdAt != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
            child: Row(
              children: [
                const Icon(
                  Icons.update_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  'Báo cáo lúc ${DateFormat('HH:mm, dd/MM/yyyy').format(report.createdAt!.toLocal())}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        _KpiGrid(metrics: metrics),
        const SizedBox(height: AppConstants.spacingLg),
        _AiContentCard(content: report.content),
        const SizedBox(height: AppConstants.spacingLg),
        _HourlyOrdersChart(items: metrics.hourlyOrders),
        const SizedBox(height: AppConstants.spacingLg),
        _TopProductsSection(items: metrics.topProducts),
        const SizedBox(height: AppConstants.spacingLg),
        _HourlyProductSalesSection(items: metrics.hourlyProductSales),
        const SizedBox(height: AppConstants.spacingLg),
        _InventorySummaryCard(summary: metrics.inventorySummary),
        const SizedBox(height: AppConstants.spacingLg),
        _InventoryRecommendationsSection(
          items: metrics.inventoryRecommendations,
        ),
      ],
    );
  }
}

class _KpiItem {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;

  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subtitle,
  });
}

class _KpiGrid extends StatelessWidget {
  final BusinessReportMetrics metrics;

  const _KpiGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem(
        label: 'Tổng doanh thu',
        value: _formatMoney(metrics.revenueSummary.totalRevenue),
        icon: Icons.payments_outlined,
        accentColor: AppColors.primary,
        subtitle:
            'Thực thu: ${_formatMoney(metrics.revenueSummary.paidRevenue)}',
      ),
      _KpiItem(
        label: 'Lợi nhuận gộp',
        value: _formatMoney(metrics.profitSummary.grossProfit),
        icon: Icons.trending_up_rounded,
        accentColor: AppColors.success,
        subtitle:
            'Biên LN: ${_formatPercent(metrics.profitSummary.grossProfitMargin)}',
      ),
      _KpiItem(
        label: 'Đơn hoàn tất',
        value: metrics.revenueSummary.completedOrderCount.toString(),
        icon: Icons.receipt_long_outlined,
        accentColor: AppColors.info,
        subtitle:
            'TB/đơn: ${_formatMoney(metrics.revenueSummary.averageOrderValue)}',
      ),
      _KpiItem(
        label: 'Giá vốn',
        value: _formatMoney(metrics.profitSummary.totalCost),
        icon: Icons.price_check_outlined,
        accentColor: AppColors.warning,
        subtitle: null,
      ),
      _KpiItem(
        label: 'Chi phí nhập hàng',
        value: _formatMoney(metrics.purchaseSummary.totalPurchaseCost),
        icon: Icons.inventory_rounded,
        accentColor: AppColors.chart3,
        subtitle: '${metrics.purchaseSummary.purchaseMovementCount} lần nhập',
      ),
      _KpiItem(
        label: 'Đơn hủy',
        value: metrics.revenueSummary.cancelledOrderCount.toString(),
        icon: Icons.cancel_outlined,
        accentColor: AppColors.error,
        subtitle: null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        const spacing = AppConstants.spacingMd;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _KpiCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _KpiItem item;

  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(item.icon, color: item.accentColor, size: 22),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: AppTextStyles.bodyXs,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w700,
                      color: item.accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiContentCard extends StatelessWidget {
  final String content;

  const _AiContentCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Nhận định AI',
      icon: Icons.auto_awesome_rounded,
      iconColor: AppColors.primary,
      headerTrailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Text(
          'AI Generated',
          style: AppTextStyles.caption.copyWith(color: AppColors.primary),
        ),
      ),
      child: content.isEmpty
          ? const _InlineEmptyState(message: 'AI chưa trả nội dung phân tích.')
          : _AiContentBody(content: content),
    );
  }
}

class _AiContentBody extends StatefulWidget {
  final String content;

  const _AiContentBody({required this.content});

  @override
  State<_AiContentBody> createState() => _AiContentBodyState();
}

class _AiContentBodyState extends State<_AiContentBody> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final lines = widget.content.split('\n');
    final hasMore = lines.length > 8;
    final displayText = _expanded || !hasMore
        ? widget.content
        : lines.take(8).join('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MarkdownLikeText(text: displayText),
        if (hasMore) ...[
          const SizedBox(height: AppConstants.spacingSm),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Thu gọn ▲' : 'Xem đầy đủ phân tích ▼',
              style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }
}

class _MarkdownLikeText extends StatelessWidget {
  final String text;

  const _MarkdownLikeText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: text.split('\n').map(_buildLine).toList(),
    );
  }

  Widget _buildLine(String line) {
    if (line.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          line.substring(4),
          style: AppTextStyles.labelSm.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }
    if (line.trim().isEmpty) return const SizedBox(height: 4);

    String processedLine = line;
    bool isBullet = false;
    if (RegExp(r'^\*\s+').hasMatch(line)) {
      processedLine = line.replaceFirst(RegExp(r'^\*\s+'), '');
      isBullet = true;
    }

    final spans = <InlineSpan>[];
    final boldPattern = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;
    for (final match in boldPattern.allMatches(processedLine)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: processedLine.substring(lastEnd, match.start),
            style: AppTextStyles.bodySm,
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: AppTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < processedLine.length) {
      spans.add(
        TextSpan(
          text: processedLine.substring(lastEnd),
          style: AppTextStyles.bodySm,
        ),
      );
    }

    final textWidget = RichText(text: TextSpan(children: spans));
    if (isBullet) {
      return Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: textWidget),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: textWidget,
    );
  }
}

class _HourlyOrdersChart extends StatelessWidget {
  final List<HourlyOrderMetric> items;

  const _HourlyOrdersChart({required this.items});

  @override
  Widget build(BuildContext context) {
    final buckets = _normalizeHourlyOrders(items);
    final maxRevenue = buckets.fold<double>(
      0,
      (v, i) => i.revenue > v ? i.revenue : v,
    );
    final peakHour = maxRevenue > 0
        ? buckets.reduce((a, b) => a.revenue > b.revenue ? a : b)
        : null;

    return _SectionCard(
      title: 'Doanh thu theo giờ',
      icon: Icons.query_stats_rounded,
      iconColor: AppColors.info,
      headerTrailing: peakHour != null && peakHour.revenue > 0
          ? _PeakBadge(hour: peakHour.hour)
          : null,
      child: SizedBox(
        height: 240,
        child: maxRevenue <= 0
            ? const _InlineEmptyState(
                message: 'Chưa có đơn hoàn tất trong khung ngày này.',
              )
            : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxRevenue / 4,
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
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          if (hour % 4 != 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('$hour', style: AppTextStyles.caption),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.textPrimary,
                      tooltipBorderRadius: BorderRadius.circular(
                        AppTheme.radiusMd,
                      ),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = buckets[group.x.toInt()];
                        if (item.orderCount == 0) return null;
                        return BarTooltipItem(
                          '${item.hour}:00–${item.hour}:59\n${item.orderCount} đơn\n${_formatMoney(item.revenue)}',
                          AppTextStyles.caption.copyWith(
                            color: AppColors.surface,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (final item in buckets)
                      BarChartGroupData(
                        x: item.hour,
                        barRods: [
                          BarChartRodData(
                            toY: item.revenue,
                            width: 10,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                            gradient: LinearGradient(
                              colors: item.hour == peakHour?.hour
                                  ? [AppColors.primary, AppColors.primaryDark]
                                  : [
                                      AppColors.primary.withValues(alpha: 0.55),
                                      AppColors.primary.withValues(alpha: 0.35),
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PeakBadge extends StatelessWidget {
  final int hour;

  const _PeakBadge({required this.hour});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 13, color: AppColors.warning),
          const SizedBox(width: 3),
          Text(
            'Cao điểm $hour:00',
            style: AppTextStyles.caption.copyWith(color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}

class _TopProductsSection extends StatelessWidget {
  final List<TopProductMetric> items;

  const _TopProductsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Top món bán chạy',
      icon: Icons.local_fire_department_rounded,
      iconColor: AppColors.error,
      child: items.isEmpty
          ? const _InlineEmptyState(
              message: 'Chưa có món bán chạy để hiển thị.',
            )
          : Column(
              children: [
                for (int i = 0; i < items.length; i++)
                  _TopProductRow(
                    item: items[i],
                    rank: i + 1,
                    isLast: i == items.length - 1,
                  ),
              ],
            ),
    );
  }
}

class _TopProductRow extends StatelessWidget {
  final TopProductMetric item;
  final int rank;
  final bool isLast;

  const _TopProductRow({
    required this.item,
    required this.rank,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (rank) {
      1 => const Color(0xFFFFB800),
      2 => const Color(0xFF9B9B9B),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      decoration: !isLast
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: AppTextStyles.labelSm.copyWith(color: rankColor),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.labelSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_formatQuantity(item.quantitySold)} phần · ${_formatMoney(item.revenue)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMoney(item.grossProfit),
                style: AppTextStyles.labelSm.copyWith(
                  color: item.grossProfit > 0
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
              ),
              Text(
                _formatPercent(item.grossProfitMargin),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HourlyProductSalesSection extends StatelessWidget {
  final List<HourlyProductSaleMetric> items;

  const _HourlyProductSalesSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Món mạnh theo giờ',
      icon: Icons.schedule_rounded,
      iconColor: AppColors.chart2,
      child: items.isEmpty
          ? const _InlineEmptyState(message: 'Chưa có dữ liệu theo khung giờ.')
          : Column(
              children: [
                for (int i = 0; i < items.length; i++)
                  _HourlyProductRow(
                    item: items[i],
                    isLast: i == items.length - 1,
                  ),
              ],
            ),
    );
  }
}

class _HourlyProductRow extends StatelessWidget {
  final HourlyProductSaleMetric item;
  final bool isLast;

  const _HourlyProductRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      decoration: !isLast
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.chart2.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              '${item.hour}:00',
              style: AppTextStyles.caption.copyWith(color: AppColors.chart2),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.labelSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_formatQuantity(item.quantitySold)} phần',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatMoney(item.revenue), style: AppTextStyles.labelSm),
              Text(
                'LN: ${_formatMoney(item.grossProfit)}',
                style: AppTextStyles.caption.copyWith(
                  color: item.grossProfit > 0
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventorySummaryCard extends StatelessWidget {
  final InventorySummary summary;

  const _InventorySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Tồn kho cần chú ý',
      icon: Icons.warehouse_outlined,
      iconColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _InventoryStatTile(
                  label: 'Sắp hết',
                  value: summary.lowStockCount,
                  color: AppColors.warning,
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: _InventoryStatTile(
                  label: 'Hết hàng',
                  value: summary.outOfStockCount,
                  color: AppColors.error,
                  icon: Icons.remove_shopping_cart_outlined,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: _InventoryStatTile(
                  label: 'Thiếu Công Thức',
                  value: summary.missingRecipeProductCount,
                  color: AppColors.info,
                  icon: Icons.receipt_outlined,
                ),
              ),
            ],
          ),
          if (summary.outOfStockItems.isNotEmpty ||
              summary.lowStockItems.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingMd),
            const Divider(),
            const SizedBox(height: AppConstants.spacingMd),
            for (final item in summary.outOfStockItems)
              _InventoryAttentionRow(item: item, isOutOfStock: true),
            for (final item in summary.lowStockItems)
              _InventoryAttentionRow(item: item, isOutOfStock: false),
          ] else ...[
            const SizedBox(height: AppConstants.spacingMd),
            const _InlineEmptyState(message: 'Tất cả sản phẩm đủ hàng.'),
          ],
        ],
      ),
    );
  }
}

class _InventoryStatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _InventoryStatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingMd,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InventoryAttentionRow extends StatelessWidget {
  final InventoryAttentionItem item;
  final bool isOutOfStock;

  const _InventoryAttentionRow({
    required this.item,
    required this.isOutOfStock,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOutOfStock ? AppColors.error : AppColors.warning;
    final statusText = isOutOfStock ? 'Hết hàng' : 'Sắp hết';
    final progressValue = item.minimumStock > 0
        ? (item.quantity / item.minimumStock).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              statusText,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: AppTextStyles.labelSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Text(
            '${_formatQuantity(item.quantity)}/${_formatQuantity(item.minimumStock)} ${item.unit}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _InventoryRecommendationsSection extends StatelessWidget {
  final List<InventoryRecommendation> items;

  const _InventoryRecommendationsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Khuyến nghị nhập kho',
      icon: Icons.recommend_rounded,
      iconColor: AppColors.success,
      child: items.isEmpty
          ? const _InlineEmptyState(message: 'Chưa có khuyến nghị kho.')
          : Column(
              children: [
                for (int i = 0; i < items.length; i++)
                  _RecommendationRow(
                    item: items[i],
                    isLast: i == items.length - 1,
                  ),
              ],
            ),
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  final InventoryRecommendation item;
  final bool isLast;

  const _RecommendationRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = item.isRestock ? AppColors.warning : AppColors.success;
    final label = item.isRestock ? 'Cần nhập' : 'Giảm nhập';
    final icon = item.isRestock
        ? Icons.add_shopping_cart_rounded
        : Icons.remove_shopping_cart_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      decoration: !isLast
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.itemName,
                        style: AppTextStyles.labelSm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingXs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        label,
                        style: AppTextStyles.caption.copyWith(color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Tồn: ${_formatQuantity(item.currentQuantity)} | Tối thiểu: ${_formatQuantity(item.minimumStock)} | Tiêu thụ: ${_formatQuantity(item.consumedQuantity)} ${item.unit}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 2),
                Text(
                  item.reason,
                  style: AppTextStyles.bodyXs,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final Widget? headerTrailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor = AppColors.primary,
    this.headerTrailing,
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?headerTrailing,
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            child,
          ],
        ),
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final String message;

  const _InlineEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
      child: Center(
        child: Text(
          message,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_graph_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Chưa có báo cáo',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              'Chọn khoảng ngày và nhấn “Tạo báo cáo” để AI phân tích dữ liệu kinh doanh.',
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Tạo báo cáo ngay'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ),
          const SizedBox(width: AppConstants.spacingXs),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _BlockedView({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 44),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              title,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

List<HourlyOrderMetric> _normalizeHourlyOrders(List<HourlyOrderMetric> items) {
  final byHour = {for (final item in items) item.hour: item};
  return [
    for (var hour = 0; hour < 24; hour++)
      byHour[hour] ?? HourlyOrderMetric(hour: hour, orderCount: 0, revenue: 0),
  ];
}

String _formatRange(DateTime fromDate, DateTime toDate) {
  final formatter = DateFormat('dd/MM/yyyy');
  return '${formatter.format(fromDate)} - ${formatter.format(toDate)}';
}

String _formatMoney(double value) {
  return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(value);
}

String _formatPercent(double value) {
  return '${NumberFormat('#,##0.##', 'vi_VN').format(value)}%';
}

String _formatQuantity(double value) {
  return NumberFormat('#,##0.##', 'vi_VN').format(value);
}
