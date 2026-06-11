enum PaymentMethod {
  cash(1, 'Tiền mặt'),
  qr(2, 'QR'),
  card(3, 'Thẻ');

  final int apiValue;
  final String label;

  const PaymentMethod(this.apiValue, this.label);
}

class SessionInvoice {
  final int invoiceId;
  final int paymentId;
  final String invoiceCode;
  final int finalAmount;

  const SessionInvoice({
    required this.invoiceId,
    required this.paymentId,
    required this.invoiceCode,
    required this.finalAmount,
  });
}
