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
  final PaymentMethod paymentMethod;
  final String invoiceCode;
  final int finalAmount;
  final PayOsPaymentData? payOsData;

  const SessionInvoice({
    required this.invoiceId,
    required this.paymentId,
    required this.paymentMethod,
    required this.invoiceCode,
    required this.finalAmount,
    this.payOsData,
  });

  bool get isQrPayment => paymentMethod == PaymentMethod.qr;
}

class PayOsPaymentData {
  final String bin;
  final String accountNumber;
  final String accountName;
  final int amount;
  final String description;
  final int orderCode;
  final String currency;
  final String paymentLinkId;
  final String status;
  final DateTime? expiredAt;
  final String checkoutUrl;
  final String qrCode;

  const PayOsPaymentData({
    required this.bin,
    required this.accountNumber,
    required this.accountName,
    required this.amount,
    required this.description,
    required this.orderCode,
    required this.currency,
    required this.paymentLinkId,
    required this.status,
    this.expiredAt,
    required this.checkoutUrl,
    required this.qrCode,
  });
}

class VietQrBank {
  final String bin;
  final String code;
  final String name;
  final String shortName;
  final String logo;

  const VietQrBank({
    required this.bin,
    required this.code,
    required this.name,
    required this.shortName,
    required this.logo,
  });
}
