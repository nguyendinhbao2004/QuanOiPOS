import 'package:flutter/material.dart';

Future<bool> showManualPaymentConfirmationDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xác nhận thanh toán'),
      content: const Text('Bạn đã nhận được tiền chưa?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Chưa'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Đã nhận'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
