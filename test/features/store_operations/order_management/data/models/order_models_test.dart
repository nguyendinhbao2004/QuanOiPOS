import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/order_management/data/models/create_order_request_model.dart';
import 'package:quan_oi/features/store_operations/order_management/data/models/order_model.dart';
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
}
