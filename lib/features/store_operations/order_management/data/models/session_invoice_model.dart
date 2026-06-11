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

    return SessionInvoiceModel(
      SessionInvoice(
        invoiceId: _intValue(json['invoiceId'] ?? json['id']),
        paymentId: _intValue(payment['id'] ?? payment['paymentId']),
        invoiceCode: json['invoiceCode']?.toString() ?? '',
        finalAmount: _intValue(json['finalAmount']),
      ),
    );
  }

  SessionInvoice toEntity() => entity;

  static int _intValue(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
