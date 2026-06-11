import 'package:flutter/material.dart';

import '../../domain/entities/session_invoice.dart';

Future<PaymentMethod?> showPaymentMethodDialog(BuildContext context) {
  return showDialog<PaymentMethod>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Chọn phương thức thanh toán'),
      children: [
        for (final method in PaymentMethod.values)
          SimpleDialogOption(
            key: Key('payment_method_${method.name}'),
            onPressed: () => Navigator.of(dialogContext).pop(method),
            child: ListTile(
              leading: Icon(_paymentMethodIcon(method)),
              title: Text(method.label),
            ),
          ),
      ],
    ),
  );
}

IconData _paymentMethodIcon(PaymentMethod method) => switch (method) {
  PaymentMethod.cash => Icons.payments_outlined,
  PaymentMethod.qr => Icons.qr_code_rounded,
  PaymentMethod.card => Icons.credit_card_rounded,
};
