import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import '../../domain/entities/system_admin_subscription_plan.dart';
import '../controllers/system_admin_package_management_state.dart';
import '../providers/system_admin_package_management_providers.dart';

class SystemAdminPackageManagement extends ConsumerWidget {
  const SystemAdminPackageManagement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(systemAdminPackageManagementProvider);
    final notifier = ref.read(systemAdminPackageManagementProvider.notifier);
    if (state.status == SystemAdminPackageManagementStatus.initial ||
        (state.status == SystemAdminPackageManagementStatus.loading &&
            state.summary == null)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingXl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (state.status == SystemAdminPackageManagementStatus.error &&
        state.summary == null) {
      return _ErrorState(message: state.errorMessage, onRetry: notifier.load);
    }
    final summary = state.summary!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          summary: summary,
          monthlyRevenue: state.monthlyRevenue,
          onAllPlans: () => notifier.setFilter(SystemAdminPlanStatus.all),
          onActivePlans: () => notifier.setFilter(SystemAdminPlanStatus.active),
        ),
        const SizedBox(height: AppConstants.spacingLg),
        _PlanUsagePanel(summary: summary),
        const SizedBox(height: AppConstants.spacingLg),
        _PlanList(
          state: state,
          onFilterChanged: notifier.setFilter,
          onPreviousPage: notifier.previousPage,
          onNextPage: notifier.nextPage,
          onCreate: () => _openPlanForm(context, ref),
          onEdit: (plan) => _openPlanForm(context, ref, planId: plan.id),
          onToggle: (plan) => _togglePlan(context, ref, plan),
          onDelete: (plan) => _deletePlan(context, ref, plan),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final SystemAdminPlanSummary summary;
  final double? monthlyRevenue;
  final VoidCallback onAllPlans;
  final VoidCallback onActivePlans;
  const _MetricGrid({
    required this.summary,
    required this.monthlyRevenue,
    required this.onAllPlans,
    required this.onActivePlans,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 720 ? 3 : 1;
      final width =
          (constraints.maxWidth - AppConstants.spacingMd * (columns - 1)) /
          columns;
      return Wrap(
        spacing: AppConstants.spacingMd,
        runSpacing: AppConstants.spacingMd,
        children: [
          SizedBox(
            width: width,
            child: _MetricCard(
              label: 'Tổng số gói',
              value: '${summary.totalPlans}',
              helper: 'Xem tất cả gói dịch vụ',
              icon: Icons.inventory_2_outlined,
              color: AppColors.primary,
              onTap: onAllPlans,
            ),
          ),
          SizedBox(
            width: width,
            child: _MetricCard(
              label: 'Gói đang bán',
              value: '${summary.activePlans}',
              helper: '${summary.inactivePlans} gói đang tạm ẩn',
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              onTap: onActivePlans,
            ),
          ),
          SizedBox(
            width: width,
            child: _MetricCard(
              label: 'Doanh thu gói',
              value: monthlyRevenue == null
                  ? '—'
                  : NumberFormat.compactCurrency(
                      locale: 'vi_VN',
                      symbol: '₫',
                      decimalDigits: 0,
                    ).format(monthlyRevenue),
              helper: 'Trong tháng hiện tại',
              icon: Icons.trending_up,
              color: AppColors.info,
            ),
          ),
        ],
      );
    },
  );
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .12),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(value, style: AppTextStyles.h2),
            const SizedBox(height: AppConstants.spacingXs),
            Text(label, style: AppTextStyles.labelSm),
            const SizedBox(height: AppConstants.spacingXs),
            Text(helper, style: AppTextStyles.bodyXs),
          ],
        ),
      ),
    ),
  );
}

class _PlanUsagePanel extends StatelessWidget {
  final SystemAdminPlanSummary summary;
  const _PlanUsagePanel({required this.summary});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tình trạng gói dịch vụ', style: AppTextStyles.h4),
          const SizedBox(height: AppConstants.spacingMd),
          if (summary.planUsage.isEmpty)
            Text('Chưa có gói nào đang bán.', style: AppTextStyles.bodySm)
          else
            ...summary.planUsage
                .expand(
                  (usage) => [
                    _UsageRow(
                      name: usage.planName,
                      value: '${usage.activeStoreCount} cửa hàng',
                      color: AppColors.success,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppConstants.spacingSm,
                      ),
                      child: Divider(),
                    ),
                  ],
                )
                .toList()
              ..removeLast(),
          if (summary.planUsage.isNotEmpty)
            const SizedBox(height: AppConstants.spacingSm),
          _UsageRow(
            name: 'Tạm ẩn',
            value: '${summary.inactivePlans} gói',
            color: AppColors.warning,
          ),
        ],
      ),
    ),
  );
}

class _UsageRow extends StatelessWidget {
  final String name;
  final String value;
  final Color color;
  const _UsageRow({
    required this.name,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: AppConstants.spacingSm),
      Expanded(child: Text(name, style: AppTextStyles.bodySm)),
      Text(value, style: AppTextStyles.labelSm),
    ],
  );
}

class _PlanList extends StatelessWidget {
  final SystemAdminPackageManagementState state;
  final ValueChanged<SystemAdminPlanStatus> onFilterChanged;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onCreate;
  final ValueChanged<SystemAdminSubscriptionPlan> onEdit;
  final ValueChanged<SystemAdminSubscriptionPlan> onToggle;
  final ValueChanged<SystemAdminSubscriptionPlan> onDelete;
  const _PlanList({
    required this.state,
    required this.onFilterChanged,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onCreate,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final page = state.page!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: AppConstants.spacingSm,
              children: [
                Text('Danh sách gói dịch vụ', style: AppTextStyles.h4),
                ElevatedButton.icon(
                  onPressed: state.isMutating ? null : onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo gói'),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Wrap(
              spacing: AppConstants.spacingSm,
              runSpacing: AppConstants.spacingSm,
              children: [
                for (final filter in SystemAdminPlanStatus.values)
                  ChoiceChip(
                    label: Text(_filterLabel(filter)),
                    selected: state.filter == filter,
                    onSelected: (_) => onFilterChanged(filter),
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            if (state.status == SystemAdminPackageManagementStatus.loading)
              const LinearProgressIndicator(),
            if (page.items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Center(
                  child: Text(
                    'Không có gói phù hợp.',
                    style: AppTextStyles.bodySm,
                  ),
                ),
              )
            else
              _PlanTable(
                items: page.items,
                isMutating: state.isMutating,
                onEdit: onEdit,
                onToggle: onToggle,
                onDelete: onDelete,
              ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                state.errorMessage!,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              children: [
                Text(
                  'Trang ${page.pageIndex}/${page.totalPages} · ${page.totalItems} gói',
                  style: AppTextStyles.bodyXs,
                ),
                const Spacer(),
                IconButton(
                  onPressed: page.pageIndex > 1 && !state.isMutating
                      ? onPreviousPage
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed:
                      page.pageIndex < page.totalPages && !state.isMutating
                      ? onNextPage
                      : null,
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

class _PlanTable extends StatelessWidget {
  final List<SystemAdminSubscriptionPlan> items;
  final bool isMutating;
  final ValueChanged<SystemAdminSubscriptionPlan> onEdit;
  final ValueChanged<SystemAdminSubscriptionPlan> onToggle;
  final ValueChanged<SystemAdminSubscriptionPlan> onDelete;
  const _PlanTable({
    required this.items,
    required this.isMutating,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('Gói')),
        DataColumn(label: Text('Giá')),
        DataColumn(label: Text('Giới hạn')),
        DataColumn(label: Text('Trạng thái')),
        DataColumn(label: Text('Thao tác')),
      ],
      rows: items
          .map(
            (plan) => DataRow(
              cells: [
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name, style: AppTextStyles.labelSm),
                      Text(
                        '${plan.durationDays} ngày',
                        style: AppTextStyles.bodyXs,
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: '₫',
                      decimalDigits: 0,
                    ).format(plan.price),
                  ),
                ),
                DataCell(
                  Text(
                    '${plan.maxStores} cửa hàng · ${plan.maxUsers} người dùng',
                    style: AppTextStyles.bodySm,
                  ),
                ),
                DataCell(_StatusLabel(isActive: plan.isActive)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Chỉnh sửa',
                        onPressed: isMutating ? null : () => onEdit(plan),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: plan.isActive ? 'Tạm ẩn' : 'Bật bán',
                        onPressed: isMutating ? null : () => onToggle(plan),
                        icon: Icon(
                          plan.isActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Xóa',
                        onPressed: isMutating ? null : () => onDelete(plan),
                        color: AppColors.error,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
          .toList(),
    ),
  );
}

class _StatusLabel extends StatelessWidget {
  final bool isActive;
  const _StatusLabel({required this.isActive});
  @override
  Widget build(BuildContext context) => Text(
    isActive ? 'Đang bán' : 'Tạm ẩn',
    style: AppTextStyles.labelXs.copyWith(
      color: isActive ? AppColors.success : AppColors.warning,
    ),
  );
}

Future<void> _openPlanForm(
  BuildContext context,
  WidgetRef ref, {
  int? planId,
}) async {
  final notifier = ref.read(systemAdminPackageManagementProvider.notifier);
  SystemAdminSubscriptionPlan? plan;
  try {
    plan = planId == null ? null : await notifier.loadPlan(planId);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_message(error))));
    }
    return;
  }
  if (!context.mounted) return;
  final request = await showDialog<UpsertSystemAdminSubscriptionPlan>(
    context: context,
    builder: (_) => _PlanFormDialog(plan: plan),
  );
  if (request == null) return;
  try {
    if (plan == null) {
      await notifier.createPlan(request);
    } else {
      await notifier.updatePlan(plan.id, request);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(plan == null ? 'Đã tạo gói.' : 'Đã cập nhật gói.'),
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_message(error))));
    }
  }
}

Future<void> _togglePlan(
  BuildContext context,
  WidgetRef ref,
  SystemAdminSubscriptionPlan plan,
) async {
  final action = plan.isActive ? 'tạm ẩn' : 'bật bán';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('${action[0].toUpperCase()}${action.substring(1)} gói?'),
      content: Text('Bạn có muốn $action gói "${plan.name}" không?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    final notifier = ref.read(systemAdminPackageManagementProvider.notifier);
    if (plan.isActive) {
      await notifier.deactivatePlan(plan.id);
    } else {
      await notifier.activatePlan(plan.id);
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_message(error))));
    }
  }
}

Future<void> _deletePlan(
  BuildContext context,
  WidgetRef ref,
  SystemAdminSubscriptionPlan plan,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Xóa gói?'),
      content: Text(
        'Gói "${plan.name}" chỉ xóa được khi chưa từng có subscription.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref
        .read(systemAdminPackageManagementProvider.notifier)
        .deletePlan(plan.id);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_message(error))));
    }
  }
}

class _PlanFormDialog extends StatefulWidget {
  final SystemAdminSubscriptionPlan? plan;
  const _PlanFormDialog({this.plan});
  @override
  State<_PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends State<_PlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _stores;
  late final TextEditingController _users;
  late final TextEditingController _features;
  late bool _isActive;
  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _name = TextEditingController(text: plan?.name ?? '');
    _price = TextEditingController(text: plan?.price.toStringAsFixed(0) ?? '');
    _duration = TextEditingController(
      text: plan?.durationDays.toString() ?? '30',
    );
    _stores = TextEditingController(text: plan?.maxStores.toString() ?? '1');
    _users = TextEditingController(text: plan?.maxUsers.toString() ?? '1');
    _features = TextEditingController(text: plan?.features.join(', ') ?? '');
    _isActive = plan?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    _stores.dispose();
    _users.dispose();
    _features.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.plan == null ? 'Tạo gói dịch vụ' : 'Chỉnh sửa gói dịch vụ',
    ),
    content: SizedBox(
      width: 520,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_name, 'Tên gói'),
              _field(_price, 'Giá (VND)', decimal: true),
              Row(
                children: [
                  Expanded(child: _field(_duration, 'Thời hạn (ngày)')),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(child: _field(_stores, 'Số cửa hàng')),
                ],
              ),
              _field(_users, 'Số người dùng'),
              _field(
                _features,
                'Tính năng (ngăn cách bằng dấu phẩy)',
                required: false,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bán ngay sau khi lưu'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      ElevatedButton(onPressed: _submit, child: const Text('Lưu')),
    ],
  );
  Widget _field(
    TextEditingController controller,
    String label, {
    bool decimal = false,
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
    child: TextFormField(
      controller: controller,
      keyboardType: label == 'Tên gói' || !required
          ? TextInputType.text
          : decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return 'Vui lòng nhập $label';
        if (label == 'Tên gói' || !required) return null;
        final number = decimal ? double.tryParse(text) : int.tryParse(text);
        if (number == null || (decimal ? number < 0 : number <= 0)) {
          return '$label không hợp lệ';
        }
        return null;
      },
    ),
  );
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      UpsertSystemAdminSubscriptionPlan(
        name: _name.text.trim(),
        price: double.parse(_price.text.trim()),
        durationDays: int.parse(_duration.text.trim()),
        maxStores: int.parse(_stores.text.trim()),
        maxUsers: int.parse(_users.text.trim()),
        features: _features.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        isActive: _isActive,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String? message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppConstants.spacingXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 36),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            message ?? 'Không thể tải quản lý gói.',
            style: AppTextStyles.bodySm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}

String _filterLabel(SystemAdminPlanStatus filter) => switch (filter) {
  SystemAdminPlanStatus.all => 'Tất cả',
  SystemAdminPlanStatus.active => 'Đang bán',
  SystemAdminPlanStatus.inactive => 'Tạm ẩn',
};
String _message(Object error) =>
    error.toString().replaceFirst('Exception: ', '');
