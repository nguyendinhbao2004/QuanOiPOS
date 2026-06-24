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
          onCreate: notifier.createReport,
        ),
        if (reportState.status == BusinessReportStatus.loading) ...[
          const SizedBox(height: AppConstants.spacingLg),
          const LinearProgressIndicator(minHeight: 2),
        ],
        if (reportState.status == BusinessReportStatus.error) ...[
          const SizedBox(height: AppConstants.spacingLg),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          store.storeName,
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppConstants.spacingXs),
        Text(
          'Phân tích doanh thu, lợi nhuận, giờ cao điểm và tồn kho',
          style: AppTextStyles.bodySm,
        ),
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final BusinessReportState state;
  final VoidCallback onPickRange;
  final VoidCallback onCreate;

  const _FilterPanel({
    required this.state,
    required this.onPickRange,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final rangeButton = OutlinedButton.icon(
              onPressed: state.isLoading ? null : onPickRange,
              icon: const Icon(Icons.date_range_outlined),
              label: Text(_formatRange(state.fromDate, state.toDate)),
            );
            final createButton = ElevatedButton.icon(
              onPressed: state.isLoading ? null : onCreate,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(state.isLoading ? 'Đang tạo...' : 'Tạo báo cáo'),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  rangeButton,
                  const SizedBox(height: AppConstants.spacingSm),
                  createButton,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: rangeButton),
                const SizedBox(width: AppConstants.spacingMd),
                createButton,
              ],
            );
          },
        ),
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
        _KpiGrid(metrics: metrics),
        const SizedBox(height: AppConstants.spacingLg),
        _AiContentCard(content: report.content),
        const SizedBox(height: AppConstants.spacingLg),
        _HourlyOrdersChart(items: metrics.hourlyOrders),
        const SizedBox(height: AppConstants.spacingLg),
        _TopProductsTable(items: metrics.topProducts),
        const SizedBox(height: AppConstants.spacingLg),
        _HourlyProductSalesTable(items: metrics.hourlyProductSales),
        const SizedBox(height: AppConstants.spacingLg),
        _InventorySummaryCard(summary: metrics.inventorySummary),
        const SizedBox(height: AppConstants.spacingLg),
        _InventoryRecommendationsTable(items: metrics.inventoryRecommendations),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final BusinessReportMetrics metrics;

  const _KpiGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem(
        'Doanh thu',
        _formatMoney(metrics.revenueSummary.totalRevenue),
        Icons.payments_outlined,
      ),
      _KpiItem(
        'Đã thu',
        _formatMoney(metrics.revenueSummary.paidRevenue),
        Icons.account_balance_wallet_outlined,
      ),
      _KpiItem(
        'Lợi nhuận gộp',
        _formatMoney(metrics.profitSummary.grossProfit),
        Icons.trending_up_rounded,
      ),
      _KpiItem(
        'Biên lợi nhuận',
        _formatPercent(metrics.profitSummary.grossProfitMargin),
        Icons.percent_rounded,
      ),
      _KpiItem(
        'Chi phí nhập',
        _formatMoney(metrics.purchaseSummary.totalPurchaseCost),
        Icons.inventory_rounded,
      ),
      _KpiItem(
        'Đơn hoàn tất',
        metrics.revenueSummary.completedOrderCount.toString(),
        Icons.receipt_long_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final spacing = AppConstants.spacingMd;
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
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(item.icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: AppTextStyles.caption),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    item.value,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
      child: Text(
        content.isEmpty ? 'AI chưa trả nội dung phân tích.' : content,
        style: AppTextStyles.bodyBase,
      ),
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
      (value, item) => item.revenue > value ? item.revenue : value,
    );

    return _SectionCard(
      title: 'Doanh thu theo giờ',
      icon: Icons.query_stats_rounded,
      child: SizedBox(
        height: 260,
        child: maxRevenue <= 0
            ? const _InlineEmptyState(
                message: 'Chưa có đơn hoàn tất trong khung ngày này.',
              )
            : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
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
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          if (hour % 3 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('$hour', style: AppTextStyles.caption),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = buckets[group.x.toInt()];
                        return BarTooltipItem(
                          '${item.hour}:00 - ${item.hour}:59\n'
                          '${item.orderCount} đơn\n'
                          '${_formatMoney(item.revenue)}',
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
                            width: 9,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                            color: AppColors.primary,
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

class _TopProductsTable extends StatelessWidget {
  final List<TopProductMetric> items;

  const _TopProductsTable({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Top món bán chạy',
      icon: Icons.local_fire_department_outlined,
      child: items.isEmpty
          ? const _InlineEmptyState(
              message: 'Chưa có món bán chạy để hiển thị.',
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Món')),
                  DataColumn(label: Text('SL')),
                  DataColumn(label: Text('Doanh thu')),
                  DataColumn(label: Text('Giá vốn')),
                  DataColumn(label: Text('Lợi nhuận')),
                  DataColumn(label: Text('Biên LN')),
                ],
                rows: [
                  for (final item in items)
                    DataRow(
                      cells: [
                        DataCell(Text(item.productName)),
                        DataCell(Text(_formatQuantity(item.quantitySold))),
                        DataCell(Text(_formatMoney(item.revenue))),
                        DataCell(Text(_formatMoney(item.cost))),
                        DataCell(Text(_formatMoney(item.grossProfit))),
                        DataCell(Text(_formatPercent(item.grossProfitMargin))),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}

class _HourlyProductSalesTable extends StatelessWidget {
  final List<HourlyProductSaleMetric> items;

  const _HourlyProductSalesTable({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Món mạnh theo giờ',
      icon: Icons.schedule_rounded,
      child: items.isEmpty
          ? const _InlineEmptyState(message: 'Chưa có dữ liệu theo khung giờ.')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Giờ')),
                  DataColumn(label: Text('Món')),
                  DataColumn(label: Text('SL')),
                  DataColumn(label: Text('Doanh thu')),
                  DataColumn(label: Text('Lợi nhuận')),
                ],
                rows: [
                  for (final item in items)
                    DataRow(
                      cells: [
                        DataCell(Text('${item.hour}:00')),
                        DataCell(Text(item.productName)),
                        DataCell(Text(_formatQuantity(item.quantitySold))),
                        DataCell(Text(_formatMoney(item.revenue))),
                        DataCell(Text(_formatMoney(item.grossProfit))),
                      ],
                    ),
                ],
              ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppConstants.spacingMd,
            runSpacing: AppConstants.spacingMd,
            children: [
              _InventoryCountChip(
                label: 'Sắp hết',
                value: summary.lowStockCount,
                color: AppColors.warning,
              ),
              _InventoryCountChip(
                label: 'Hết hàng',
                value: summary.outOfStockCount,
                color: AppColors.error,
              ),
              _InventoryCountChip(
                label: 'Thiếu công thức',
                value: summary.missingRecipeProductCount,
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          ...[
            for (final item in [
              ...summary.outOfStockItems,
              ...summary.lowStockItems,
            ])
              _InventoryItemRow(item: item),
          ],
          if (summary.lowStockItems.isEmpty && summary.outOfStockItems.isEmpty)
            const _InlineEmptyState(message: 'Chưa có item tồn kho cần chú ý.'),
        ],
      ),
    );
  }
}

class _InventoryRecommendationsTable extends StatelessWidget {
  final List<InventoryRecommendation> items;

  const _InventoryRecommendationsTable({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Khuyến nghị kho',
      icon: Icons.recommend_outlined,
      child: items.isEmpty
          ? const _InlineEmptyState(message: 'Chưa có khuyến nghị kho.')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Loại')),
                  DataColumn(label: Text('Item')),
                  DataColumn(label: Text('Tồn hiện tại')),
                  DataColumn(label: Text('Tối thiểu')),
                  DataColumn(label: Text('Tiêu thụ')),
                  DataColumn(label: Text('Đã nhập')),
                  DataColumn(label: Text('Lý do')),
                ],
                rows: [
                  for (final item in items)
                    DataRow(
                      cells: [
                        DataCell(_RecommendationBadge(item: item)),
                        DataCell(Text(item.itemName)),
                        DataCell(
                          Text(
                            '${_formatQuantity(item.currentQuantity)} ${item.unit}',
                          ),
                        ),
                        DataCell(
                          Text(
                            '${_formatQuantity(item.minimumStock)} ${item.unit}',
                          ),
                        ),
                        DataCell(Text(_formatQuantity(item.consumedQuantity))),
                        DataCell(Text(_formatQuantity(item.importedQuantity))),
                        DataCell(
                          SizedBox(width: 240, child: Text(item.reason)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
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
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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

class _InventoryCountChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _InventoryCountChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.labelSm.copyWith(color: color),
      ),
    );
  }
}

class _InventoryItemRow extends StatelessWidget {
  final InventoryAttentionItem item;

  const _InventoryItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.itemName,
              style: AppTextStyles.bodySm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Text(
            '${_formatQuantity(item.quantity)} / '
            '${_formatQuantity(item.minimumStock)} ${item.unit}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _RecommendationBadge extends StatelessWidget {
  final InventoryRecommendation item;

  const _RecommendationBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.isRestock ? AppColors.warning : AppColors.success;
    final label = item.isRestock ? 'Cần nhập' : 'Giảm nhập';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final String message;

  const _InlineEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
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
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          children: [
            const Icon(
              Icons.auto_graph_rounded,
              color: AppColors.primary,
              size: 44,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Chọn khoảng ngày và tạo báo cáo để xem phân tích AI.',
              style: AppTextStyles.bodyBase,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Tạo báo cáo'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(child: Text(message, style: AppTextStyles.bodySm)),
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
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

class _KpiItem {
  final String label;
  final String value;
  final IconData icon;

  const _KpiItem(this.label, this.value, this.icon);
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
