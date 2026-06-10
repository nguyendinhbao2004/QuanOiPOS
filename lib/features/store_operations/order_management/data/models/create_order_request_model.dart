import '../../domain/entities/create_order_draft.dart';

class CreateOrderRequestModel {
  final CreateOrderDraft draft;

  const CreateOrderRequestModel(this.draft);

  Map<String, dynamic> toJson() {
    return {
      'storeId': draft.storeId,
      'tableSessionId': draft.tableSessionId,
      'orderType': 'DineIn',
      'customerId': null,
      'items': draft.items
          .map(
            (item) => {
              'productId': item.productId,
              'variantId': item.variantId,
              'note': item.note,
              'toppings': item.toppings
                  .map(
                    (topping) => {
                      'toppingId': topping.toppingId,
                      'quantity': topping.quantity,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };
  }
}
