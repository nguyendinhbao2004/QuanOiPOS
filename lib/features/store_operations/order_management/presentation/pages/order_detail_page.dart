import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../domain/entities/order.dart';
import '../controllers/order_states.dart';
import '../providers/order_management_providers.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Đơn #$orderId')),
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
