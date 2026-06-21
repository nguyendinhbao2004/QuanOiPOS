import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../config/router_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/session_invoice.dart';
import '../controllers/order_notifiers.dart';
import '../controllers/order_states.dart';
import '../providers/order_management_providers.dart';
import '../widgets/payment_method_dialog.dart';
import '../widgets/qr_payment_dialog.dart';

class OrderListPage extends ConsumerWidget {
  final int storeId;
  final int tableSessionId;
  final bool isSessionOpen;

  const OrderListPage({
    super.key,
    required this.storeId,
    required this.tableSessionId,
    required this.isSessionOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));
    if (accessState.status != StoreAccessStatus.ready) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _AccessStateView(
          state: accessState,
          onRetry: () => ref
              .read(storeAccessNotifierProvider(storeId).notifier)
              .loadAccess(),
        ),
      );
    }

    final access = OrderSessionAccess(
      storeId: storeId,
      tableSessionId: tableSessionId,
      isSessionOpen: isSessionOpen,
      canViewOrder: accessState.can(AppPermissionCodes.orderView),
      canCreateOrder: accessState.can(AppPermissionCodes.orderCreate),
      canCloseSession: accessState.can(AppPermissionCodes.tableCloseSession),
    );
    final state = ref.watch(orderListNotifierProvider(access));
    final notifier = ref.read(orderListNotifierProvider(access).notifier);
    final checkoutState = ref.watch(sessionCheckoutNotifierProvider(access));
    final checkoutNotifier = ref.read(
      sessionCheckoutNotifierProvider(access).notifier,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar:
          state.status == OrderLoadStatus.ready &&
              state.orders.isNotEmpty &&
              access.isSessionOpen &&
              access.canViewOrder &&
              access.canCloseSession
          ? SafeArea(
              minimum: const EdgeInsets.all(AppConstants.spacingMd),
              child: ElevatedButton.icon(
                key: const Key('checkout_session_button'),
                onPressed: checkoutState.isProcessing
                    ? null
                    : () => _checkoutSession(
                        context,
                        ref,
                        access,
                        checkoutNotifier,
                        checkoutState,
                      ),
                icon: checkoutState.isProcessing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payments_outlined),
                label: Text(
                  checkoutState.isProcessing
                      ? _checkoutStatusLabel(checkoutState.status)
                      : checkoutState.invoice?.isQrPayment == true
                      ? 'Xem lại QR'
                      : checkoutState.paymentConfirmed
                      ? 'Đóng phiên lại'
                      : 'Thanh toán phiên',
                ),
              ),
            )
          : null,
      floatingActionButton: access.isSessionOpen && access.canCreateOrder
          ? FloatingActionButton(
              key: const Key('add_order_button'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              onPressed: () async {
                final created = await context.pushNamed<bool>(
                  RouteNames.storeOrderCreate,
                  pathParameters: {
                    'storeId': '$storeId',
                    'tableSessionId': '$tableSessionId',
                  },
                );
                if (created == true) await notifier.load();
              },
              child: const Icon(Icons.add_rounded),
            )
          : null,
      appBar: AppBar(title: Text('Phiên #$tableSessionId')),
      body: switch (state.status) {
        OrderLoadStatus.initial || OrderLoadStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        OrderLoadStatus.forbidden => _MessageView(
          icon: Icons.lock_outline_rounded,
          title: 'Không có quyền xem đơn hàng',
          message: state.errorMessage ?? 'Vui lòng liên hệ quản trị viên.',
        ),
        OrderLoadStatus.error => _MessageView(
          icon: Icons.error_outline_rounded,
          title: 'Không thể tải đơn hàng',
          message: state.errorMessage ?? 'Vui lòng thử lại.',
          actionLabel: 'Thử lại',
          onAction: notifier.load,
        ),
        OrderLoadStatus.ready => RefreshIndicator(
          onRefresh: notifier.load,
          child: state.orders.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 180),
                    _MessageView(
                      icon: Icons.receipt_long_outlined,
                      title: 'Chưa có đơn hàng',
                      message: 'Các đơn của phiên bàn sẽ xuất hiện tại đây.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.spacingMd,
                    AppConstants.spacingMd,
                    AppConstants.spacingMd,
                    96,
                  ),
                  itemCount: state.orders.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppConstants.spacingSm),
                  itemBuilder: (context, index) {
                    final order = state.orders[index];
                    return _OrderCard(
                      order: order,
                      onTap: () async {
                        final changed = await context.pushNamed<bool>(
                          RouteNames.storeOrderDetail,
                          pathParameters: {
                            'storeId': '$storeId',
                            'tableSessionId': '$tableSessionId',
                            'orderId': '${order.id}',
                          },
                          queryParameters: {
                            'sessionOpen': isSessionOpen.toString(),
                          },
                        );
                        if (changed == true) await notifier.load();
                      },
                    );
                  },
                ),
        ),
      },
    );
  }
}

Future<void> _checkoutSession(
  BuildContext context,
  WidgetRef ref,
  OrderSessionAccess access,
  SessionCheckoutNotifier notifier,
  SessionCheckoutState currentState,
) async {
  if (currentState.paymentConfirmed) {
    await _retryCloseSession(context, ref, access, notifier);
    return;
  }

  if (currentState.invoice?.isQrPayment == true) {
    await showQrPaymentDialog(context, currentState.invoice!);
    return;
  }

  final method = await showPaymentMethodDialog(context);
  if (method == null || !context.mounted) return;

  try {
    await notifier.checkout(method);
    if (!context.mounted) return;
    final state = ref.read(sessionCheckoutNotifierProvider(access));
    if (method == PaymentMethod.qr && state.invoice != null) {
      await showQrPaymentDialog(context, state.invoice!);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanh toán và đóng phiên thành công')),
    );
    context.pop(true);
  } catch (_) {
    if (!context.mounted) return;
    final state = ref.read(sessionCheckoutNotifierProvider(access));
    await _showCheckoutError(context, ref, access, notifier, state);
  }
}

Future<void> _retryCloseSession(
  BuildContext context,
  WidgetRef ref,
  OrderSessionAccess access,
  SessionCheckoutNotifier notifier,
) async {
  try {
    await notifier.retryCloseSession();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã đóng phiên bàn')));
    context.pop(true);
  } catch (_) {
    if (!context.mounted) return;
    final state = ref.read(sessionCheckoutNotifierProvider(access));
    await _showCheckoutError(context, ref, access, notifier, state);
  }
}

Future<void> _showCheckoutError(
  BuildContext context,
  WidgetRef ref,
  OrderSessionAccess access,
  SessionCheckoutNotifier notifier,
  SessionCheckoutState state,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        state.paymentConfirmed
            ? 'Đã thanh toán, chưa đóng phiên'
            : 'Thanh toán chưa hoàn tất',
      ),
      content: Text(state.errorMessage ?? 'Vui lòng thử lại.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Đóng'),
        ),
        if (state.paymentConfirmed)
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _retryCloseSession(context, ref, access, notifier);
            },
            child: const Text('Thử đóng phiên lại'),
          ),
      ],
    ),
  );
}

String _checkoutStatusLabel(SessionCheckoutStatus status) => switch (status) {
  SessionCheckoutStatus.creatingInvoice => 'Đang tạo hóa đơn...',
  SessionCheckoutStatus.confirmingPayment => 'Đang xác nhận...',
  SessionCheckoutStatus.awaitingQrPayment => 'Chờ thanh toán QR',
  SessionCheckoutStatus.closingSession => 'Đang đóng phiên...',
  _ => 'Đang xử lý...',
};

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = switch (order.status) {
      OrderStatus.pending => AppColors.warning,
      OrderStatus.completed => AppColors.success,
      OrderStatus.cancelled => AppColors.error,
      OrderStatus.unknown => AppColors.textMuted,
    };
    return Card(
      child: InkWell(
        key: Key('order_card_${order.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: const Icon(Icons.receipt_long_outlined),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đơn #${order.id}',
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      '${order.items.length} món • ${_formatTime(order.createdAt)}',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      order.status.label,
                      style: AppTextStyles.caption.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              Text(
                _currency(order.finalAmount ?? order.totalAmount),
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppConstants.spacingXs),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessStateView extends StatelessWidget {
  final StoreAccessState state;
  final VoidCallback onRetry;

  const _AccessStateView({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      StoreAccessStatus.initial || StoreAccessStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      StoreAccessStatus.forbidden => _MessageView(
        icon: Icons.lock_outline_rounded,
        title: 'Không có quyền truy cập',
        message: state.errorMessage ?? 'Không thể truy cập cửa hàng này.',
      ),
      StoreAccessStatus.error => _MessageView(
        icon: Icons.error_outline_rounded,
        title: 'Không thể tải quyền cửa hàng',
        message: state.errorMessage ?? 'Vui lòng thử lại.',
        actionLabel: 'Thử lại',
        onAction: onRetry,
      ),
      StoreAccessStatus.ready => const SizedBox.shrink(),
    };
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textMuted),
            const SizedBox(height: AppConstants.spacingMd),
            Text(title, style: AppTextStyles.h4, textAlign: TextAlign.center),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppConstants.spacingLg),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _currency(int value) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);

String _formatTime(DateTime? value) {
  if (value == null) return 'Chưa có thời gian';
  return DateFormat('HH:mm dd/MM/yyyy').format(value.toLocal());
}
