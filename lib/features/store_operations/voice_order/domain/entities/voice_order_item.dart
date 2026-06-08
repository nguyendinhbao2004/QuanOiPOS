class VoiceOrderItem {
  final int productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final double confidence;

  const VoiceOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.confidence,
  });
}
