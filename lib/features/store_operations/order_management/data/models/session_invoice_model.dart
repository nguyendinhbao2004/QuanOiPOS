import '../../domain/entities/session_invoice.dart';

class SessionInvoiceModel {
  final SessionInvoice entity;

  const SessionInvoiceModel(this.entity);

  factory SessionInvoiceModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid invoice data');
    }

    final payments = json['payments'];
    final payment = payments is List && payments.isNotEmpty
        ? payments.first
        : null;
    if (payment is! Map<String, dynamic>) {
      throw const FormatException('Invoice does not contain a payment');
    }
    final paymentMethod = _paymentMethodValue(payment['paymentMethod']);
    final payOsData = _payOsData(json['payOSData']);
    if (paymentMethod == PaymentMethod.qr && payOsData == null) {
      throw const FormatException('QR invoice does not contain PayOS data');
    }

    return SessionInvoiceModel(
      SessionInvoice(
        invoiceId: _intValue(json['invoiceId'] ?? json['id']),
        paymentId: _intValue(payment['id'] ?? payment['paymentId']),
        paymentMethod: paymentMethod,
        invoiceCode: json['invoiceCode']?.toString() ?? '',
        finalAmount: _intValue(json['finalAmount']),
        payOsData: payOsData,
      ),
    );
  }

  SessionInvoice toEntity() => entity;

  static int _intValue(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static PaymentMethod _paymentMethodValue(Object? value) {
    final methodValue = _intValue(value);
    for (final method in PaymentMethod.values) {
      if (method.apiValue == methodValue) return method;
    }
    return PaymentMethod.cash;
  }

  static PayOsPaymentData? _payOsData(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return PayOsPaymentData(
      bin: value['bin']?.toString() ?? '',
      accountNumber: value['accountNumber']?.toString() ?? '',
      accountName: value['accountName']?.toString() ?? '',
      amount: _intValue(value['amount']),
      description: value['description']?.toString() ?? '',
      orderCode: _intValue(value['orderCode']),
      currency: value['currency']?.toString() ?? '',
      paymentLinkId: value['paymentLinkId']?.toString() ?? '',
      status: value['status']?.toString() ?? '',
      expiredAt: DateTime.tryParse(value['expiredAt']?.toString() ?? ''),
      checkoutUrl: value['checkoutUrl']?.toString() ?? '',
      qrCode: value['qrCode']?.toString() ?? '',
    );
  }
}
