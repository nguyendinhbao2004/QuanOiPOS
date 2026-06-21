import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/order_management/data/models/create_order_request_model.dart';
import 'package:quan_oi/features/store_operations/order_management/data/models/order_model.dart';
import 'package:quan_oi/features/store_operations/order_management/data/models/session_invoice_model.dart';
import 'package:quan_oi/features/store_operations/order_management/data/models/viet_qr_bank_model.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/entities/create_order_draft.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/entities/order.dart';

void main() {
  test('parses order snapshots and nullable values', () {
    final order = OrderModel.fromJson({
      'id': 7001,
      'storeId': 5,
      'tableSessionId': 501,
      'shiftSessionId': null,
      'orderType': 1,
      'status': 1,
      'totalAmount': 45000,
      'createdAt': '2026-06-10T10:10:00Z',
      'items': [
        {
          'id': 8001,
          'orderId': 7001,
          'productId': 101,
          'variantId': 201,
          'productNameSnapshot': 'Trà sữa',
          'variantNameSnapshot': 'Size L',
          'status': 2,
          'unitPrice': 35000,
          'note': 'Ít đá',
          'toppings': [
            {
              'id': 9001,
              'orderItemId': 8001,
              'toppingId': 3,
              'toppingNameSnapshot': 'Trân châu',
              'quantity': 2,
              'unitPrice': 5000,
              'totalPrice': 10000,
            },
          ],
        },
      ],
    }).toEntity();

    expect(order.type, OrderType.dineIn);
    expect(order.status, OrderStatus.pending);
    expect(order.shiftSessionId, isNull);
    expect(order.items.single.status, OrderItemStatus.preparing);
    expect(order.items.single.displayPrice, 45000);
    expect(order.items.single.toppings.single.name, 'Trân châu');
  });

  test('serializes create order contract', () {
    final json = CreateOrderRequestModel(
      const CreateOrderDraft(
        storeId: 5,
        tableSessionId: 501,
        items: [
          CreateOrderItemDraft(
            productId: 101,
            variantId: 201,
            note: 'Ít đá',
            toppings: [CreateOrderToppingDraft(toppingId: 3, quantity: 2)],
          ),
        ],
      ),
    ).toJson();

    expect(json['orderType'], 'DineIn');
    expect(json['customerId'], isNull);
    expect(json['items'], [
      {
        'productId': 101,
        'variantId': 201,
        'note': 'Ít đá',
        'toppings': [
          {'toppingId': 3, 'quantity': 2},
        ],
      },
    ]);
  });

  test('SessionInvoiceModel reads pending payment from invoice response', () {
    final invoice = SessionInvoiceModel.fromJson({
      'invoiceId': 1001,
      'invoiceCode': 'INV-TS-501',
      'finalAmount': 145000,
      'payments': [
        {'id': 1101, 'paymentMethod': 1, 'status': 1},
      ],
    }).toEntity();

    expect(invoice.invoiceId, 1001);
    expect(invoice.paymentId, 1101);
    expect(invoice.paymentMethod.apiValue, 1);
    expect(invoice.invoiceCode, 'INV-TS-501');
    expect(invoice.finalAmount, 145000);
  });

  test('SessionInvoiceModel reads PayOS data for QR invoice response', () {
    final invoice = SessionInvoiceModel.fromJson({
      'invoiceId': 28,
      'invoiceCode': 'INV-ORD-60-20260621021316718',
      'finalAmount': 10000,
      'payments': [
        {'id': 28, 'paymentMethod': 2, 'status': 1},
      ],
      'payOSData': {
        'bin': '970448',
        'accountNumber': 'CAS0932958302',
        'accountName': 'Nguyen Dinh Bao',
        'amount': 10000,
        'description': 'CSY4HNUEJC7 PAY 28',
        'orderCode': 281782007998,
        'currency': 'VND',
        'paymentLinkId': 'af81765f288b4d758a14e260c6e8112b',
        'status': 'PENDING',
        'checkoutUrl':
            'https://pay.payos.vn/web/af81765f288b4d758a14e260c6e8112b',
        'qrCode': '000201010212',
      },
    }).toEntity();

    expect(invoice.paymentMethod.apiValue, 2);
    expect(invoice.payOsData?.bin, '970448');
    expect(invoice.payOsData?.accountNumber, 'CAS0932958302');
    expect(invoice.payOsData?.amount, 10000);
    expect(invoice.payOsData?.description, 'CSY4HNUEJC7 PAY 28');
  });

  test('SessionInvoiceModel rejects QR invoice without PayOS data', () {
    expect(
      () => SessionInvoiceModel.fromJson({
        'invoiceId': 28,
        'invoiceCode': 'INV-ORD-60',
        'finalAmount': 10000,
        'payments': [
          {'id': 28, 'paymentMethod': 2, 'status': 1},
        ],
      }),
      throwsFormatException,
    );
  });

  test('VietQrBankModel reads VietQR bank response aliases', () {
    final bank = VietQrBankModel.fromJson({
      'id': 26,
      'name': 'Ngân hàng TMCP Phương Đông',
      'code': 'OCB',
      'bin': '970448',
      'shortName': 'OCB',
      'logo': 'https://cdn.vietqr.io/img/OCB.png',
      'short_name': 'OCB',
    }).toEntity();

    expect(bank.bin, '970448');
    expect(bank.shortName, 'OCB');
    expect(bank.name, 'Ngân hàng TMCP Phương Đông');
    expect(bank.logo, 'https://api.vietqr.io/img/OCB.png');
  });

  test('VietQrBankModel falls back to snake case short name', () {
    final bank = VietQrBankModel.fromJson({
      'name': 'Ngân hàng TMCP Phương Đông',
      'code': 'OCB',
      'bin': '970448',
      'short_name': 'OCB',
      'logo': 'https://cdn.vietqr.io/img/OCB.png',
    }).toEntity();

    expect(bank.shortName, 'OCB');
  });
}
