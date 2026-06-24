enum InventoryDeductionMode {
  recipeOnly('RecipeOnly', 'Chỉ trừ nguyên liệu'),
  productOnly('ProductOnly', 'Chỉ trừ thành phẩm'),
  variantOnly('VariantOnly', 'Trừ tồn theo tùy chọn'),
  both('Both', 'Trừ thành phẩm và nguyên liệu');

  final String apiValue;
  final String label;

  const InventoryDeductionMode(this.apiValue, this.label);

  static InventoryDeductionMode fromApi(Object? value) {
    final text = value?.toString().trim().toLowerCase();
    return InventoryDeductionMode.values.firstWhere(
      (mode) => mode.apiValue.toLowerCase() == text,
      orElse: () => InventoryDeductionMode.recipeOnly,
    );
  }
}
