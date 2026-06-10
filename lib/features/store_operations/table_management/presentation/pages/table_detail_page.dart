import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../domain/entities/dining_table.dart';
import '../../domain/entities/table_session.dart';
import '../../domain/entities/table_status.dart';
import '../controllers/table_detail_state.dart';
import '../providers/table_management_providers.dart';

class TableDetailPage extends ConsumerWidget {
  final int storeId;
  final int tableId;

  const TableDetailPage({
    super.key,
    required this.storeId,
    required this.tableId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: switch (accessState.status) {
          StoreAccessStatus.initial ||
          StoreAccessStatus.loading => const _LoadingView(),
          StoreAccessStatus.forbidden => _BlockedView(
            icon: Icons.lock_outline_rounded,
            title: 'Không có quyền truy cập',
            message:
                accessState.errorMessage ??
                'Tài khoản của bạn không có quyền truy cập cửa hàng này.',
            actionLabel: 'Quay lại',
            onAction: () => context.pop(false),
          ),
          StoreAccessStatus.error => _BlockedView(
            icon: Icons.error_outline_rounded,
            title: 'Không thể tải quyền cửa hàng',
            message: accessState.errorMessage ?? 'Vui lòng thử lại sau.',
            actionLabel: 'Thử lại',
            onAction: () => ref
                .read(storeAccessNotifierProvider(storeId).notifier)
                .loadAccess(),
          ),
          StoreAccessStatus.ready => _AccessReadyView(
            storeId: storeId,
            tableId: tableId,
            accessState: accessState,
          ),
        },
      ),
    );
  }
}

class _AccessReadyView extends ConsumerWidget {
  final int storeId;
  final int tableId;
  final StoreAccessState accessState;

  const _AccessReadyView({
    required this.storeId,
    required this.tableId,
    required this.accessState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = TableDetailAccess(
      storeId: storeId,
      tableId: tableId,
      canViewTable: accessState.can(AppPermissionCodes.tableView),
      canUpdateTable: accessState.can(AppPermissionCodes.tableUpdate),
      canOpenSession: accessState.can(AppPermissionCodes.tableOpenSession),
    );
    final state = ref.watch(tableDetailNotifierProvider(access));
    final notifier = ref.read(tableDetailNotifierProvider(access).notifier);

    return switch (state.status) {
      TableDetailStatus.initial ||
      TableDetailStatus.loading => const _LoadingView(),
      TableDetailStatus.forbidden => _BlockedView(
        icon: Icons.visibility_off_outlined,
        title: 'Bạn chưa có quyền xem chi tiết bàn',
        message:
            state.errorMessage ??
            'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền.',
        actionLabel: 'Quay lại',
        onAction: () => context.pop(false),
      ),
      TableDetailStatus.error => _BlockedView(
        icon: Icons.error_outline_rounded,
        title: 'Không thể tải chi tiết bàn',
        message: state.errorMessage ?? 'Vui lòng thử lại sau.',
        actionLabel: 'Thử lại',
        onAction: notifier.load,
      ),
      TableDetailStatus.ready => _ReadyContent(
        state: state,
        access: access,
        onBack: () => context.pop(state.hasChanged),
        onRefresh: notifier.load,
        onToggleDisabled: () => _runMutation(
          context,
          notifier.toggleDisabled,
          successMessage: 'Đã cập nhật trạng thái bàn',
        ),
        onOpenSession: () => _runMutation(
          context,
          notifier.openSession,
          successMessage: 'Đã mở phiên bàn',
        ),
      ),
    };
  }
}

class _ReadyContent extends StatelessWidget {
  final TableDetailState state;
  final TableDetailAccess access;
  final VoidCallback onBack;
  final Future<void> Function() onRefresh;
  final VoidCallback onToggleDisabled;
  final VoidCallback onOpenSession;

  const _ReadyContent({
    required this.state,
    required this.access,
    required this.onBack,
    required this.onRefresh,
    required this.onToggleDisabled,
    required this.onOpenSession,
  });

  @override
  Widget build(BuildContext context) {
    final table = state.table!;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingMd,
          AppConstants.spacingSm,
          AppConstants.spacingMd,
          AppConstants.spacingXxl,
        ),
        children: [
          _Header(
            table: table,
            areaName: state.areaName,
            canToggleStatus:
                access.canUpdateTable &&
                (table.status == TableStatus.available ||
                    table.status == TableStatus.disabled),
            isMutating: state.isMutating,
            onBack: onBack,
            onToggleDisabled: onToggleDisabled,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          _ActionSection(
            table: table,
            state: state,
            canOpenSession: access.canOpenSession,
            isMutating: state.isMutating,
            onOpenSession: onOpenSession,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          _HistorySection(sessions: state.historySessions),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DiningTable table;
  final String areaName;
  final bool canToggleStatus;
  final bool isMutating;
  final VoidCallback onBack;
  final VoidCallback onToggleDisabled;

  const _Header({
    required this.table,
    required this.areaName,
    required this.canToggleStatus,
    required this.isMutating,
    required this.onBack,
    required this.onToggleDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(table.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Quay lại',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Text(
                    table.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            _InfoRow(
              icon: Icons.layers_outlined,
              label: 'Khu vực',
              value: areaName,
            ),
            _InfoRow(
              icon: Icons.event_seat_outlined,
              label: 'Sức chứa',
              value: '${table.capacity} chỗ',
            ),
            Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    icon: Icons.circle_rounded,
                    iconColor: statusColor,
                    label: 'Trạng thái',
                    value: table.status.label,
                    valueColor: statusColor,
                  ),
                ),
                if (canToggleStatus)
                  Switch(
                    key: const Key('table_detail_status_toggle'),
                    value: table.status == TableStatus.available,
                    onChanged: isMutating ? null : (_) => onToggleDisabled(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor ?? AppColors.textMuted),
          const SizedBox(width: AppConstants.spacingSm),
          SizedBox(width: 92, child: Text(label, style: AppTextStyles.caption)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.labelSm.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final DiningTable table;
  final TableDetailState state;
  final bool canOpenSession;
  final bool isMutating;
  final VoidCallback onOpenSession;

  const _ActionSection({
    required this.table,
    required this.state,
    required this.canOpenSession,
    required this.isMutating,
    required this.onOpenSession,
  });

  @override
  Widget build(BuildContext context) {
    if (table.status == TableStatus.disabled) {
      return const SizedBox.shrink();
    }

    if (table.status == TableStatus.occupied) {
      final currentSession = state.currentSession;
      if (currentSession == null) {
        return const _EmptyCard(
          icon: Icons.info_outline_rounded,
          title: 'Chưa có dữ liệu phiên hiện tại',
          message: 'Không tìm thấy phiên bàn đang mở cho bàn này.',
        );
      }

      return _SessionCard(title: 'Phiên bàn hiện tại', session: currentSession);
    }

    if (table.status == TableStatus.available ||
        table.status == TableStatus.reserved) {
      if (!canOpenSession) {
        return const _EmptyCard(
          icon: Icons.lock_outline_rounded,
          title: 'Không có quyền mở phiên',
          message: 'Bạn cần quyền mở phiên bàn để thực hiện thao tác này.',
        );
      }

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const Key('table_detail_open_session_button'),
          onPressed: isMutating ? null : onOpenSession,
          icon: isMutating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: const Text('Mở phiên bàn'),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _HistorySection extends StatelessWidget {
  final List<TableSession> sessions;

  const _HistorySection({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lịch sử phiên bàn',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            if (sessions.isEmpty)
              const _EmptyInlineState(
                icon: Icons.history_rounded,
                message: 'Chưa có phiên đã đóng hoặc đã hủy.',
              )
            else
              for (final session in sessions) ...[
                _SessionListTile(session: session),
                if (session != sessions.last) const Divider(height: 1),
              ],
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String title;
  final TableSession session;

  const _SessionCard({required this.title, required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            _SessionListTile(session: session, showDividerPadding: false),
          ],
        ),
      ),
    );
  }
}

class _SessionListTile extends StatelessWidget {
  final TableSession session;
  final bool showDividerPadding;

  const _SessionListTile({
    required this.session,
    this.showDividerPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _sessionStatusColor(session.status);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: showDividerPadding ? AppConstants.spacingSm : 0,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.12),
            foregroundColor: statusColor,
            child: const Icon(Icons.receipt_long_outlined),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phiên #${session.id}',
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Text(_sessionTimeRange(session), style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(
            session.status.label,
            style: AppTextStyles.caption.copyWith(color: statusColor),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 40),
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
          ],
        ),
      ),
    );
  }
}

class _EmptyInlineState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyInlineState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingLg),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(child: Text(message, style: AppTextStyles.bodySm)),
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
            SizedBox(
              width: 180,
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

Future<void> _runMutation(
  BuildContext context,
  Future<void> Function() action, {
  required String successMessage,
}) async {
  try {
    await action();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}

Color _statusColor(TableStatus status) {
  return switch (status) {
    TableStatus.available => AppColors.success,
    TableStatus.occupied => AppColors.warning,
    TableStatus.reserved => AppColors.info,
    TableStatus.disabled => AppColors.textMuted,
    TableStatus.unknown => AppColors.textMuted,
  };
}

Color _sessionStatusColor(TableSessionStatus status) {
  return switch (status) {
    TableSessionStatus.open => AppColors.success,
    TableSessionStatus.closed => AppColors.info,
    TableSessionStatus.cancelled => AppColors.error,
    TableSessionStatus.unknown => AppColors.textMuted,
  };
}

String _sessionTimeRange(TableSession session) {
  final openTime = _formatTime(session.openTime);
  final closeTime = _formatTime(session.closeTime);

  if (closeTime == null) {
    return openTime == null ? 'Chưa có thời gian mở' : 'Mở lúc $openTime';
  }

  if (openTime == null) {
    return 'Đóng lúc $closeTime';
  }

  return '$openTime - $closeTime';
}

String? _formatTime(DateTime? value) {
  if (value == null) {
    return null;
  }

  return DateFormat('HH:mm dd/MM/yyyy').format(value.toLocal());
}
