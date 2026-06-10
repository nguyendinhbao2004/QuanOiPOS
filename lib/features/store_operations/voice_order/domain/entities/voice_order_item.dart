import 'voice_order_topping.dart';

class VoiceOrderItem {
  final int? productId;
  final String productName;
  final int? variantId;
  final String? variantName;
  final int quantity;
  final bool available;
  final String? message;
  final String? note;
  final List<VoiceOrderTopping> toppings;

  const VoiceOrderItem({
    required this.productId,
    required this.productName,
    this.variantId,
    this.variantName,
    required this.quantity,
    required this.available,
    this.message,
    this.note,
    this.toppings = const [],
  });

  VoiceOrderItem copyWith({
    Object? productId = _unchanged,
    String? productName,
    Object? variantId = _unchanged,
    Object? variantName = _unchanged,
    int? quantity,
    bool? available,
    Object? message = _unchanged,
    Object? note = _unchanged,
    List<VoiceOrderTopping>? toppings,
  }) {
    return VoiceOrderItem(
      productId: productId == _unchanged ? this.productId : productId as int?,
      productName: productName ?? this.productName,
      variantId: variantId == _unchanged ? this.variantId : variantId as int?,
      variantName: variantName == _unchanged
          ? this.variantName
          : variantName as String?,
      quantity: quantity ?? this.quantity,
      available: available ?? this.available,
      message: message == _unchanged ? this.message : message as String?,
      note: note == _unchanged ? this.note : note as String?,
      toppings: toppings ?? this.toppings,
    );
  }
}

const Object _unchanged = Object();
