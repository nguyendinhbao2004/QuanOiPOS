class ProductVariantDraft {
  final int? id;
  final String name;
  final int price;
  final int costPrice;
  final bool isDefault;

  const ProductVariantDraft({
    this.id,
    required this.name,
    required this.price,
    this.costPrice = 0,
    required this.isDefault,
  });
}
