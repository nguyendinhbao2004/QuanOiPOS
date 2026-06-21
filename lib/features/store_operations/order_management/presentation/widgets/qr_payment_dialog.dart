import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import '../../domain/entities/session_invoice.dart';
import '../providers/order_management_providers.dart';

Future<void> showQrPaymentDialog(BuildContext context, SessionInvoice invoice) {
  return showDialog<void>(
    context: context,
    builder: (_) => QrPaymentDialog(invoice: invoice),
  );
}

class QrPaymentDialog extends ConsumerWidget {
  final SessionInvoice invoice;

  const QrPaymentDialog({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payOsData = invoice.payOsData;
    if (payOsData == null) {
      return AlertDialog(
        title: const Text('Không có dữ liệu QR'),
        content: const Text('Hóa đơn này chưa có thông tin thanh toán QR.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      );
    }

    final banksState = ref.watch(vietQrBanksProvider);
    final banks = banksState.valueOrNull ?? const <VietQrBank>[];
    final bank = _findBank(banks, payOsData.bin);

    return AlertDialog(
      title: const Text('Thanh toán QR'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Image.network(
                  _vietQrImageUrl(payOsData),
                  key: const Key('vietqr_payment_image'),
                  height: 240,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 240,
                    child: Center(child: Icon(Icons.qr_code_2_rounded)),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              _BankHeader(bank: bank, payOsData: payOsData),
              const SizedBox(height: AppConstants.spacingMd),
              _CopyableInfoRow(
                label: 'Số tài khoản',
                value: payOsData.accountNumber,
              ),
              _CopyableInfoRow(
                label: 'Chủ tài khoản',
                value: payOsData.accountName,
              ),
              _CopyableInfoRow(
                label: 'Số tiền',
                value: _currency(payOsData.amount),
                copyValue: payOsData.amount.toString(),
              ),
              _CopyableInfoRow(label: 'Nội dung', value: payOsData.description),
              if (banksState.hasError) ...[
                const SizedBox(height: AppConstants.spacingSm),
                Text(
                  'Không thể tải tên ngân hàng, vui lòng dùng thông tin tài khoản bên trên.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _BankHeader extends StatelessWidget {
  final VietQrBank? bank;
  final PayOsPaymentData payOsData;

  const _BankHeader({required this.bank, required this.payOsData});

  @override
  Widget build(BuildContext context) {
    final bankName = bank == null || bank!.shortName.isEmpty
        ? 'Ngân hàng ${payOsData.bin}'
        : bank!.shortName;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: bank == null || bank!.logo.isEmpty
              ? const Icon(Icons.account_balance_rounded)
              : Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingXs),
                  child: Image.network(
                    bank!.logo,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.account_balance_rounded),
                  ),
                ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bankName, style: AppTextStyles.label),
              if (bank != null && bank!.name.isNotEmpty)
                Text(bank!.name, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 112, child: Text(label, style: AppTextStyles.bodySm)),
          Expanded(
            child: SelectableText(
              value,
              key: Key('qr_payment_$label'),
              style: AppTextStyles.labelSm,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyableInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? copyValue;

  const _CopyableInfoRow({
    required this.label,
    required this.value,
    this.copyValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _InfoRow(label: label, value: value),
        ),
        IconButton(
          tooltip: 'Sao chép',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: copyValue ?? value));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Đã sao chép')));
          },
          icon: const Icon(Icons.copy_rounded),
        ),
      ],
    );
  }
}

VietQrBank? _findBank(List<VietQrBank> banks, String bin) {
  final normalizedBin = bin.trim();
  for (final bank in banks) {
    if (bank.bin.trim() == normalizedBin) return bank;
  }
  return null;
}

String _vietQrImageUrl(PayOsPaymentData data) {
  final addInfo = Uri.encodeQueryComponent(data.description);
  return 'https://img.vietqr.io/image/'
      '${data.bin}-${data.accountNumber}-vietqr_pro.jpg'
      '?addInfo=$addInfo&amount=${data.amount}';
}

String _currency(int value) =>
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);
