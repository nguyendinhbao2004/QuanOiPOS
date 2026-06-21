import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

class OrderDetailPage extends ConsumerWidget {
  final int storeId;
  final int orderId;

  const OrderDetailPage({
    super.key,
    required this.storeId,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));
    if (accessState.status != StoreAccessStatus.ready) {
      return Scaffold(
        appBar: AppBar(title: Text('Đơn #$orderId')),
        body: Center(
          child:
              accessState.status == StoreAccessStatus.loading ||
                  accessState.status == StoreAccessStatus.initial
              ? const CircularProgressIndicator()
              : Text(accessState.errorMessage ?? 'Không thể truy cập cửa hàng'),
        ),
      );
    }

    final access = OrderDetailAccess(
      orderId: orderId,
      canViewOrder: accessState.can(AppPermissionCodes.orderView),
    );
    final state = ref.watch(orderDetailNotifierProvider(access));
    final notifier = ref.read(orderDetailNotifierProvider(access).notifier);
    final paymentState = ref.watch(orderPaymentNotifierProvider(access));
    final paymentNotifier = ref.read(
      orderPaymentNotifierProvider(access).notifier,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Đơn #$orderId')),
      bottomNavigationBar:
          state.status == OrderLoadStatus.ready && state.order!.canPay
          ? SafeArea(
              minimum: const EdgeInsets.all(AppConstants.spacingMd),
              child: ElevatedButton.icon(
                key: const Key('pay_order_button'),
                onPressed: paymentState.isProcessing
                    ? null
                    : () => _payOrder(
                        context,
                        ref,
                        access,
                        paymentNotifier,
                        paymentState,
                      ),
                icon: paymentState.isProcessing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payments_outlined),
                label: Text(
                  paymentState.isProcessing
                      ? _paymentStatusLabel(paymentState.status)
                      : paymentState.invoice?.isQrPayment == true
                      ? 'Xem lại QR'
                      : 'Thanh toán đơn',
                ),
              ),
            )
          : null,
      body: switch (state.status) {
        OrderLoadStatus.initial || OrderLoadStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        OrderLoadStatus.forbidden => const _DetailMessage(
          icon: Icons.lock_outline_rounded,
          text: 'Bạn chưa có quyền xem đơn hàng.',
        ),
        OrderLoadStatus.error => _DetailMessage(
          icon: Icons.error_outline_rounded,
          text: state.errorMessage ?? 'Không thể tải đơn hàng.',
          onRetry: notifier.load,
        ),
        OrderLoadStatus.ready => _OrderContent(
          order: state.order!,
          onRefresh: notifier.load,
        ),
      },
    );
  }
}

class _OrderContent extends StatelessWidget {
  final Order order;
  final Future<void> Function() onRefresh;

  const _OrderContent({required this.order, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                children: [
                  _SummaryRow(label: 'Trạng thái', value: order.status.label),
                  _SummaryRow(
                    label: 'Thời gian',
                    value: order.createdAt == null
                        ? 'Chưa có'
                        : DateFormat(
                            'HH:mm dd/MM/yyyy',
                          ).format(order.createdAt!.toLocal()),
                  ),
                  _SummaryRow(label: 'Số món', value: '${order.items.length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text('Chi tiết món', style: AppTextStyles.h4),
          const SizedBox(height: AppConstants.spacingSm),
          for (final item in order.items) ...[
            _OrderItemCard(item: item),
            const SizedBox(height: AppConstants.spacingSm),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: _SummaryRow(
                label: 'Tổng cộng',
                value: _currency(order.finalAmount ?? order.totalAmount),
                emphasized: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _payOrder(
  BuildContext context,
  WidgetRef ref,
  OrderDetailAccess access,
  OrderPaymentNotifier notifier,
  OrderPaymentState currentState,
) async {
  if (currentState.invoice?.isQrPayment == true) {
    await showQrPaymentDialog(context, currentState.invoice!);
    return;
  }

  final method =
      currentState.invoice?.paymentMethod ??
      await showPaymentMethodDialog(context);
  if (method == null || !context.mounted) return;

  try {
    await notifier.pay(method);
    if (!context.mounted) return;
    final state = ref.read(orderPaymentNotifierProvider(access));
    if (method == PaymentMethod.qr && state.invoice != null) {
      await showQrPaymentDialog(context, state.invoice!);
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Thanh toán đơn thành công')));
    context.pop(true);
  } catch (_) {
    if (!context.mounted) return;
    final state = ref.read(orderPaymentNotifierProvider(access));
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thanh toán chưa hoàn tất'),
        content: Text(state.errorMessage ?? 'Vui lòng thử lại.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đóng'),
          ),
          if (state.invoice != null)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _payOrder(context, ref, access, notifier, state);
              },
              child: const Text('Thử xác nhận lại'),
            ),
        ],
      ),
    );
  }
}

String _paymentStatusLabel(OrderPaymentStatus status) => switch (status) {
  OrderPaymentStatus.creatingInvoice => 'Đang tạo hóa đơn...',
  OrderPaymentStatus.confirmingPayment => 'Đang xác nhận...',
  OrderPaymentStatus.awaitingQrPayment => 'Chờ thanh toán QR',
  _ => 'Đang xử lý...',
};

class _OrderItemCard extends StatelessWidget {
  final OrderItem item;

  const _OrderItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(_currency(item.displayPrice), style: AppTextStyles.label),
              ],
            ),
            if (item.variantName.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingXs),
              Text(item.variantName, style: AppTextStyles.bodySm),
            ],
            for (final topping in item.toppings)
              Padding(
                padding: const EdgeInsets.only(top: AppConstants.spacingXs),
                child: Text(
                  '+ ${topping.name} x${topping.quantity}',
                  style: AppTextStyles.bodySm,
                ),
              ),
            if (item.note.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Text('Ghi chú: ${item.note}', style: AppTextStyles.caption),
            ],
            const SizedBox(height: AppConstants.spacingSm),
            Text(item.status.label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)
        : AppTextStyles.bodySm;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _DetailMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  const _DetailMessage({required this.icon, required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.textMuted),
          const SizedBox(height: AppConstants.spacingMd),
          Text(text, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ],
      ),
    );
  }
}

String _currency(int value) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);
