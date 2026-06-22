import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/system_admin_account.dart';
import '../controllers/system_admin_account_management_state.dart';
import '../providers/system_admin_account_management_providers.dart';

class SystemAdminAccountManagement extends ConsumerWidget {
  const SystemAdminAccountManagement({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(systemAdminAccountManagementProvider);
    final notifier = ref.read(systemAdminAccountManagementProvider.notifier);
    if (state.summary == null &&
        state.status != SystemAdminAccountManagementStatus.error) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingXl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (state.summary == null) {
      return _Error(message: state.errorMessage, onRetry: notifier.load);
    }
    final summary = state.summary!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Summary(
          summary: summary,
          onAll: () => notifier.openAccounts(),
          onType: (type) => notifier.openAccounts(type: type),
          onActive: () =>
              notifier.openAccounts(status: SystemAdminAccountStatus.active),
          onSuspended: () =>
              notifier.openAccounts(status: SystemAdminAccountStatus.suspended),
          onPending: notifier.openPending,
        ),
        const SizedBox(height: AppConstants.spacingLg),
        _Content(state: state),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final SystemAdminAccountSummary summary;
  final VoidCallback onAll, onActive, onSuspended, onPending;
  final ValueChanged<SystemAdminAccountType> onType;
  const _Summary({
    required this.summary,
    required this.onAll,
    required this.onType,
    required this.onActive,
    required this.onSuspended,
    required this.onPending,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LayoutBuilder(
        builder: (context, c) {
          final count = c.maxWidth >= 720 ? 3 : 1;
          final width =
              (c.maxWidth - AppConstants.spacingMd * (count - 1)) / count;
          return Wrap(
            spacing: AppConstants.spacingMd,
            runSpacing: AppConstants.spacingMd,
            children: [
              SizedBox(
                width: width,
                child: _Metric(
                  'Tổng account',
                  '${summary.totalAccounts}',
                  'Tất cả loại tài khoản',
                  Icons.manage_accounts_outlined,
                  AppColors.primary,
                  onAll,
                ),
              ),
              SizedBox(
                width: width,
                child: _Metric(
                  'SystemAdmin',
                  '${summary.systemAdminAccounts}',
                  'Tài khoản quản trị nền tảng',
                  Icons.verified_user_outlined,
                  AppColors.info,
                  () => onType(SystemAdminAccountType.systemAdmin),
                ),
              ),
              SizedBox(
                width: width,
                child: _Metric(
                  'StoreUser',
                  '${summary.storeUserAccounts}',
                  'Chủ quán và nhân sự cửa hàng',
                  Icons.storefront_outlined,
                  AppColors.success,
                  () => onType(SystemAdminAccountType.storeUser),
                ),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: AppConstants.spacingLg),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Trạng thái account', style: AppTextStyles.h4),
              const SizedBox(height: AppConstants.spacingMd),
              _Status(
                'Đang hoạt động',
                '${summary.activeAccounts}',
                AppColors.success,
                onActive,
              ),
              const Divider(height: AppConstants.spacingLg),
              _Status(
                'Chờ xác minh',
                '${summary.pendingRegistrationCount}',
                AppColors.warning,
                onPending,
              ),
              const Divider(height: AppConstants.spacingLg),
              _Status(
                'Đã khóa',
                '${summary.suspendedAccounts}',
                AppColors.error,
                onSuspended,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  final String label, value, helper;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Metric(
    this.label,
    this.value,
    this.helper,
    this.icon,
    this.color,
    this.onTap,
  );
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

class _Status extends StatelessWidget {
  final String name, value;
  final Color color;
  final VoidCallback onTap;
  const _Status(this.name, this.value, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(child: Text(name, style: AppTextStyles.bodySm)),
        Text(value, style: AppTextStyles.labelSm),
        const SizedBox(width: AppConstants.spacingXs),
        const Icon(Icons.chevron_right, size: 18),
      ],
    ),
  );
}

class _Content extends ConsumerWidget {
  final SystemAdminAccountManagementState state;
  const _Content({required this.state});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(systemAdminAccountManagementProvider.notifier);
    final currentId = ref.watch(authNotifierProvider).accountId;
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
                Text(
                  state.view == SystemAdminAccountView.accounts
                      ? 'Danh sách account'
                      : 'Đăng ký chờ xác minh',
                  style: AppTextStyles.h4,
                ),
                TextButton.icon(
                  onPressed: state.view == SystemAdminAccountView.accounts
                      ? notifier.openPending
                      : notifier.openAccounts,
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(
                    state.view == SystemAdminAccountView.accounts
                        ? 'Xem chờ xác minh'
                        : 'Quay lại account',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            _Filters(state: state),
            const SizedBox(height: AppConstants.spacingMd),
            if (state.status == SystemAdminAccountManagementStatus.loading)
              const LinearProgressIndicator(),
            if (state.view == SystemAdminAccountView.accounts)
              _AccountsTable(
                page: state.accounts,
                currentId: currentId,
                isMutating: state.isMutating,
                onDetail: (id) => _showDetail(context, ref, id),
                onStatus: (a) => _showStatus(context, ref, a),
              )
            else
              _PendingTable(page: state.pending),
            if (state.errorMessage != null) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                state.errorMessage!,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
              ),
            ],
            _Pagination(
              page: state.view == SystemAdminAccountView.accounts
                  ? state.accounts
                  : state.pending,
              onPrev: notifier.previousPage,
              onNext: notifier.nextPage,
            ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends ConsumerStatefulWidget {
  final SystemAdminAccountManagementState state;
  const _Filters({required this.state});
  @override
  ConsumerState<_Filters> createState() => _FiltersState();
}

class _FiltersState extends ConsumerState<_Filters> {
  late final TextEditingController _search;
  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.state.query.keyword);
  }

  @override
  void didUpdateWidget(covariant _Filters old) {
    super.didUpdateWidget(old);
    if (old.state.query.keyword != widget.state.query.keyword) {
      _search.text = widget.state.query.keyword;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.state.query;
    final n = ref.read(systemAdminAccountManagementProvider.notifier);
    return Wrap(
      spacing: AppConstants.spacingSm,
      runSpacing: AppConstants.spacingSm,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Tìm ID, tên, email, số điện thoại',
            ),
            onSubmitted: (v) => n.updateQuery(q.copyWith(keyword: v.trim())),
          ),
        ),
        if (widget.state.view == SystemAdminAccountView.accounts) ...[
          DropdownButton<SystemAdminAccountType>(
            value: q.accountType,
            items: SystemAdminAccountType.values
                .map((x) => DropdownMenuItem(value: x, child: Text(_type(x))))
                .toList(),
            onChanged: (x) {
              if (x != null) n.updateQuery(q.copyWith(accountType: x));
            },
          ),
          DropdownButton<SystemAdminAccountStatus>(
            value: q.status,
            items: SystemAdminAccountStatus.values
                .map((x) => DropdownMenuItem(value: x, child: Text(_status(x))))
                .toList(),
            onChanged: (x) {
              if (x != null) n.updateQuery(q.copyWith(status: x));
            },
          ),
          DropdownButton<SystemAdminAccountSort>(
            value: q.sort,
            items: SystemAdminAccountSort.values
                .map((x) => DropdownMenuItem(value: x, child: Text(_sort(x))))
                .toList(),
            onChanged: (x) {
              if (x != null) n.updateQuery(q.copyWith(sort: x));
            },
          ),
          IconButton(
            tooltip: 'Đảo chiều sắp xếp',
            onPressed: () => n.updateQuery(
              q.copyWith(
                direction: q.direction == SystemAdminSortDirection.asc
                    ? SystemAdminSortDirection.desc
                    : SystemAdminSortDirection.asc,
              ),
            ),
            icon: Icon(
              q.direction == SystemAdminSortDirection.asc
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _pickRange(
              context,
              q,
              (from, to) =>
                  n.updateQuery(q.copyWith(createdFrom: from, createdTo: to)),
            ),
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              q.createdFrom == null
                  ? 'Ngày tạo'
                  : _range(q.createdFrom!, q.createdTo!),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _pickRange(
              context,
              q,
              (from, to) => n.updateQuery(
                q.copyWith(lastLoginFrom: from, lastLoginTo: to),
              ),
            ),
            icon: const Icon(Icons.login_outlined),
            label: Text(
              q.lastLoginFrom == null
                  ? 'Lần đăng nhập'
                  : _range(q.lastLoginFrom!, q.lastLoginTo!),
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> _pickRange(
  BuildContext context,
  SystemAdminAccountQuery q,
  void Function(DateTime, DateTime) save,
) async {
  final r = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
    initialDateRange: q.createdFrom == null
        ? null
        : DateTimeRange(
            start: q.createdFrom!,
            end: q.createdTo ?? q.createdFrom!,
          ),
  );
  if (r != null) save(r.start, r.end);
}

String _range(DateTime a, DateTime? b) =>
    '${DateFormat('dd/MM/yy').format(a)} - ${DateFormat('dd/MM/yy').format(b ?? a)}';

class _AccountsTable extends StatelessWidget {
  final SystemAdminPage<SystemAdminAccount>? page;
  final int? currentId;
  final bool isMutating;
  final ValueChanged<int> onDetail;
  final ValueChanged<SystemAdminAccount> onStatus;
  const _AccountsTable({
    required this.page,
    required this.currentId,
    required this.isMutating,
    required this.onDetail,
    required this.onStatus,
  });
  @override
  Widget build(BuildContext context) {
    final items = page?.items ?? const <SystemAdminAccount>[];
    if (items.isEmpty) return const _Empty('Không có account phù hợp.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Họ tên')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Điện thoại')),
          DataColumn(label: Text('Loại')),
          DataColumn(label: Text('Trạng thái')),
          DataColumn(label: Text('Ngày tạo')),
          DataColumn(label: Text('Lần đăng nhập')),
          DataColumn(label: Text('Thao tác')),
        ],
        rows: items
            .map(
              (a) => DataRow(
                cells: [
                  DataCell(Text('${a.id}')),
                  DataCell(Text(a.fullName)),
                  DataCell(Text(a.email)),
                  DataCell(Text(a.phone)),
                  DataCell(Text(_type(a.accountType))),
                  DataCell(_Badge(a.status)),
                  DataCell(Text(_date(a.createdAt))),
                  DataCell(
                    Text(a.lastLogin == null ? '—' : _date(a.lastLogin!)),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Xem chi tiết',
                          onPressed: () => onDetail(a.id),
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                        if (a.id != currentId)
                          IconButton(
                            tooltip:
                                a.status == SystemAdminAccountStatus.suspended
                                ? 'Mở khóa'
                                : 'Khóa account',
                            onPressed: isMutating ? null : () => onStatus(a),
                            icon: Icon(
                              a.status == SystemAdminAccountStatus.suspended
                                  ? Icons.lock_open_outlined
                                  : Icons.lock_outline,
                            ),
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
}

class _PendingTable extends StatelessWidget {
  final SystemAdminPage<PendingRegistration>? page;
  const _PendingTable({required this.page});
  @override
  Widget build(BuildContext context) {
    final items = page?.items ?? const <PendingRegistration>[];
    if (items.isEmpty) return const _Empty('Không có đăng ký chờ xác minh.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Họ tên')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Tạo lúc')),
          DataColumn(label: Text('Hết hạn')),
          DataColumn(label: Text('Lần thử')),
        ],
        rows: items
            .map(
              (p) => DataRow(
                cells: [
                  DataCell(Text(p.fullName)),
                  DataCell(Text(p.email)),
                  DataCell(Text(_date(p.createdAt))),
                  DataCell(Text(_date(p.expiresAt))),
                  DataCell(Text('${p.attemptCount}/${p.maxAttempts}')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final SystemAdminAccountStatus status;
  const _Badge(this.status);
  @override
  Widget build(BuildContext context) {
    final c = status == SystemAdminAccountStatus.active
        ? AppColors.success
        : status == SystemAdminAccountStatus.suspended
        ? AppColors.error
        : AppColors.warning;
    return Text(
      _status(status),
      style: AppTextStyles.labelXs.copyWith(color: c),
    );
  }
}

class _Pagination extends StatelessWidget {
  final SystemAdminPage? page;
  final VoidCallback onPrev, onNext;
  const _Pagination({
    required this.page,
    required this.onPrev,
    required this.onNext,
  });
  @override
  Widget build(BuildContext context) {
    if (page == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingMd),
      child: Row(
        children: [
          Text(
            'Trang ${page!.pageIndex}/${page!.totalPages} · ${page!.totalItems} mục',
            style: AppTextStyles.bodyXs,
          ),
          const Spacer(),
          IconButton(
            onPressed: page!.pageIndex > 1 ? onPrev : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: page!.pageIndex < page!.totalPages ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppConstants.spacingXl),
    child: Center(child: Text(text, style: AppTextStyles.bodySm)),
  );
}

Future<void> _showDetail(BuildContext context, WidgetRef ref, int id) async {
  try {
    final detail = await ref
        .read(systemAdminAccountManagementProvider.notifier)
        .loadDetail(id);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(detail.fullName),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info('Email', detail.email),
                _info('Điện thoại', detail.phone),
                _info('Loại account', _type(detail.accountType)),
                _info('Trạng thái', _status(detail.status)),
                _info('Ngày tạo', _date(detail.createdAt)),
                _info(
                  'Lần đăng nhập',
                  detail.lastLogin == null ? '—' : _date(detail.lastLogin!),
                ),
                const SizedBox(height: AppConstants.spacingMd),
                Text('Cửa hàng liên kết', style: AppTextStyles.h4),
                const SizedBox(height: AppConstants.spacingSm),
                if (detail.storeMemberships.isEmpty)
                  Text(
                    'Không có cửa hàng liên kết.',
                    style: AppTextStyles.bodySm,
                  ),
                for (final m in detail.storeMemberships)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingSm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.storeName, style: AppTextStyles.labelSm),
                          Text(
                            '${m.address} · ${m.phone}',
                            style: AppTextStyles.bodyXs,
                          ),
                          Text(
                            '${m.isOwner ? 'Chủ sở hữu' : 'Vai trò'}: ${m.roleName ?? '—'} · ${m.storeStatus}',
                            style: AppTextStyles.bodyXs,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_error(e))));
    }
  }
}

Widget _info(String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: AppConstants.spacingXs),
  child: RichText(
    text: TextSpan(
      style: AppTextStyles.bodySm,
      children: [
        TextSpan(text: '$label: ', style: AppTextStyles.labelSm),
        TextSpan(text: value),
      ],
    ),
  ),
);
Future<void> _showStatus(
  BuildContext context,
  WidgetRef ref,
  SystemAdminAccount account,
) async {
  final target = account.status == SystemAdminAccountStatus.suspended
      ? SystemAdminAccountStatus.active
      : SystemAdminAccountStatus.suspended;
  final reason = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(
        target == SystemAdminAccountStatus.suspended
            ? 'Khóa account?'
            : 'Mở khóa account?',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            target == SystemAdminAccountStatus.suspended
                ? 'Account sẽ bị đăng xuất khi refresh token tiếp theo và không thể đăng nhập lại.'
                : 'Account sẽ được mở khóa.',
          ),
          if (target == SystemAdminAccountStatus.suspended) ...[
            const SizedBox(height: AppConstants.spacingMd),
            TextField(
              controller: reason,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Lý do (tùy chọn)'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            target == SystemAdminAccountStatus.suspended ? 'Khóa' : 'Mở khóa',
          ),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    reason.dispose();
    return;
  }
  try {
    await ref
        .read(systemAdminAccountManagementProvider.notifier)
        .updateStatus(account.id, status: target, reason: reason.text);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_error(error))));
    }
  } finally {
    reason.dispose();
  }
}

class _Error extends StatelessWidget {
  final String? message;
  final Future<void> Function() onRetry;
  const _Error({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message ?? 'Không thể tải account.', style: AppTextStyles.bodySm),
        OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}

String _type(SystemAdminAccountType t) => switch (t) {
  SystemAdminAccountType.all => 'Tất cả loại',
  SystemAdminAccountType.systemAdmin => 'SystemAdmin',
  SystemAdminAccountType.storeUser => 'StoreUser',
};
String _status(SystemAdminAccountStatus s) => switch (s) {
  SystemAdminAccountStatus.all => 'Tất cả trạng thái',
  SystemAdminAccountStatus.active => 'Đang hoạt động',
  SystemAdminAccountStatus.inactive => 'Không hoạt động',
  SystemAdminAccountStatus.suspended => 'Đã khóa',
};
String _sort(SystemAdminAccountSort s) => switch (s) {
  SystemAdminAccountSort.id => 'ID',
  SystemAdminAccountSort.fullName => 'Họ tên',
  SystemAdminAccountSort.email => 'Email',
  SystemAdminAccountSort.createdAt => 'Ngày tạo',
  SystemAdminAccountSort.lastLogin => 'Lần đăng nhập',
  SystemAdminAccountSort.accountType => 'Loại account',
  SystemAdminAccountSort.status => 'Trạng thái',
};
String _date(DateTime d) => DateFormat('dd/MM/yyyy HH:mm').format(d.toLocal());
String _error(Object e) => e.toString().replaceFirst('Exception: ', '');
