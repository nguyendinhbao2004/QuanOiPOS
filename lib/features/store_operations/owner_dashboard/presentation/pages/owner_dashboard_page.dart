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
import '../../domain/entities/owner_dashboard_insight.dart';
import '../../domain/entities/owner_dashboard_insight_type.dart';
import '../../domain/entities/owner_dashboard_metrics.dart';
import '../../domain/entities/owner_dashboard_period.dart';
import '../../domain/entities/owner_dashboard_top_product.dart';
import '../controllers/owner_dashboard_state.dart';
import '../providers/owner_dashboard_providers.dart';

class OwnerDashboardPage extends ConsumerWidget {
  final int storeId;

  const OwnerDashboardPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan doanh thu'),
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
        title: 'Bạn chưa có quyền xem tổng quan',
        message: 'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền.',
        actionLabel: 'Về tổng quan cửa hàng',
        onAction: () => context.goNamed(
          RouteNames.storeOverview,
          pathParameters: {'storeId': accessContext.store.id.toString()},
        ),
      );
    }

    final dashboardState = ref.watch(
      ownerDashboardNotifierProvider(accessContext.store.id),
    );
    final notifier = ref.read(
      ownerDashboardNotifierProvider(accessContext.store.id).notifier,
    );

    return RefreshIndicator(
      onRefresh: notifier.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingMd,
          AppConstants.spacingMd,
          AppConstants.spacingMd,
          AppConstants.spacingXxl,
        ),
        children: [
          _DashboardHeader(
            store: accessContext.store,
            period: dashboardState.period,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          _FilterPanel(
            state: dashboardState,
            onPeriodTypeChanged: notifier.changePeriodType,
            onInsightTypeChanged: notifier.changeInsightType,
            onDatePicked: notifier.changeAnchorDate,
            onRefresh: notifier.load,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          switch (dashboardState.status) {
            OwnerDashboardStatus.initial ||
            OwnerDashboardStatus.loading => const _InsightLoadingCard(),
            OwnerDashboardStatus.error => _InsightErrorCard(
              message:
                  dashboardState.errorMessage ??
                  'Không thể tạo phân tích doanh thu.',
              onRetry: notifier.load,
            ),
            OwnerDashboardStatus.ready => _InsightContent(
              insight: dashboardState.insight,
            ),
          },
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final Store store;
  final OwnerDashboardPeriod period;

  const _DashboardHeader({required this.store, required this.period});

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
          _formatRange(period),
          style: AppTextStyles.bodySm,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final OwnerDashboardState state;
  final ValueChanged<OwnerDashboardPeriodType> onPeriodTypeChanged;
  final ValueChanged<OwnerDashboardInsightType> onInsightTypeChanged;
  final ValueChanged<DateTime> onDatePicked;
  final VoidCallback onRefresh;

  const _FilterPanel({
    required this.state,
    required this.onPeriodTypeChanged,
    required this.onInsightTypeChanged,
    required this.onDatePicked,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<OwnerDashboardPeriodType>(
              initialValue: state.period.type,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Khoảng thời gian',
                prefixIcon: Icon(Icons.date_range_outlined),
              ),
              items: [
                for (final type in OwnerDashboardPeriodType.values)
                  DropdownMenuItem<OwnerDashboardPeriodType>(
                    value: type,
                    child: Text(type.label),
                  ),
              ],
              onChanged: state.isLoading
                  ? null
                  : (type) {
                      if (type != null) {
                        onPeriodTypeChanged(type);
                      }
                    },
            ),
            const SizedBox(height: AppConstants.spacingMd),
            InkWell(
              onTap: state.isLoading
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: state.period.anchorDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );

                      if (picked != null) {
                        onDatePicked(picked);
                      }
                    },
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày tham chiếu',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                  suffixIcon: Icon(Icons.expand_more_rounded),
                ),
                child: Text(
                  _formatRange(state.period),
                  style: AppTextStyles.input.copyWith(
                    color: state.isLoading
                        ? AppColors.textDisabled
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<OwnerDashboardInsightType>(
                    initialValue: state.type,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Loại phân tích',
                      prefixIcon: Icon(Icons.auto_awesome_outlined),
                    ),
                    items: [
                      for (final type in OwnerDashboardInsightType.values)
                        DropdownMenuItem<OwnerDashboardInsightType>(
                          value: type,
                          child: Text(type.label),
                        ),
                    ],
                    onChanged: state.isLoading
                        ? null
                        : (type) {
                            if (type != null) {
                              onInsightTypeChanged(type);
                            }
                          },
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                IconButton(
                  tooltip: 'Tạo lại phân tích',
                  onPressed: state.isLoading ? null : onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightContent extends StatelessWidget {
  final OwnerDashboardInsight? insight;

  const _InsightContent({required this.insight});

  @override
  Widget build(BuildContext context) {
    final currentInsight = insight;
    if (currentInsight == null) {
      return const _EmptyInsightCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricsGrid(metrics: currentInsight.metrics),
        const SizedBox(height: AppConstants.spacingLg),
        _AiContentCard(insight: currentInsight),
        const SizedBox(height: AppConstants.spacingLg),
        _TopProductsCard(metrics: currentInsight.metrics),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final OwnerDashboardMetrics metrics;

  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricData(
        title: 'Tổng doanh thu',
        value: _formatCurrency(metrics.totalRevenue),
        icon: Icons.trending_up_rounded,
        color: AppColors.primary,
      ),
      _MetricData(
        title: 'Đã thanh toán',
        value: _formatCurrency(metrics.paidRevenue),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.success,
      ),
      _MetricData(
        title: 'Đơn hoàn thành',
        value: _formatNumber(metrics.completedOrderCount),
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.info,
      ),
      _MetricData(
        title: 'Đơn đã hủy',
        value: _formatNumber(metrics.cancelledOrderCount),
        icon: Icons.cancel_outlined,
        color: AppColors.error,
      ),
      _MetricData(
        title: 'Giá trị TB',
        value: _formatCurrency(metrics.averageOrderValue),
        icon: Icons.receipt_long_outlined,
        color: AppColors.chart2,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 3 : 2,
            mainAxisSpacing: AppConstants.spacingMd,
            crossAxisSpacing: AppConstants.spacingMd,
            childAspectRatio: isWide ? 1.65 : 1.18,
          ),
          itemBuilder: (context, index) => _MetricCard(data: items[index]),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              data.value,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              data.title,
              style: AppTextStyles.bodyXs,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AiContentCard extends StatelessWidget {
  final OwnerDashboardInsight insight;

  const _AiContentCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final createdAt = insight.createdAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.type == OwnerDashboardInsightType.trend
                            ? 'Phân tích xu hướng'
                            : 'Gợi ý cải thiện',
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          'Tạo lúc ${DateFormat('HH:mm dd/MM/yyyy').format(createdAt.toLocal())}',
                          style: AppTextStyles.bodyXs,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              insight.content.trim().isEmpty
                  ? 'Chưa có nội dung phân tích.'
                  : insight.content,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final OwnerDashboardMetrics metrics;

  const _TopProductsCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final products = metrics.topProducts;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top món bán chạy',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            if (products.isEmpty)
              Text(
                'Chưa có món bán chạy trong khoảng thời gian này.',
                style: AppTextStyles.bodySm,
              )
            else
              for (var index = 0; index < products.length; index++) ...[
                _TopProductTile(rank: index + 1, product: products[index]),
                if (index < products.length - 1) const Divider(height: 1),
              ],
          ],
        ),
      ),
    );
  }
}

class _TopProductTile extends StatelessWidget {
  final int rank;
  final OwnerDashboardTopProduct product;

  const _TopProductTile({required this.rank, required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              '$rank',
              style: AppTextStyles.labelXs.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Text(
              product.productName,
              style: AppTextStyles.labelSm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Text('${product.orderItemCount} lượt', style: AppTextStyles.bodyXs),
        ],
      ),
    );
  }
}

class _InsightLoadingCard extends StatelessWidget {
  const _InsightLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingXl),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _InsightErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InsightErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _EmptyInsightCard extends StatelessWidget {
  const _EmptyInsightCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingLg),
        child: Text('Chưa có dữ liệu phân tích cho khoảng thời gian này.'),
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
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
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
    return const ColoredBox(
      color: AppColors.background,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

String _formatRange(OwnerDashboardPeriod period) {
  final formatter = DateFormat('dd/MM/yyyy');
  if (period.type == OwnerDashboardPeriodType.day) {
    return formatter.format(period.fromDate);
  }

  return '${formatter.format(period.fromDate)} - ${formatter.format(period.toDate)}';
}

String _formatCurrency(double value) {
  return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);
}

String _formatNumber(num value) {
  return NumberFormat.decimalPattern('vi_VN').format(value);
}
