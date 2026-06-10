enum ProductType {
  food(1, 'Thực phẩm'),
  drink(2, 'Đồ uống');

  final int value;
  final String label;

  const ProductType(this.value, this.label);

  static ProductType fromValue(Object? value) {
    if (value is num) {
      return _fromInt(value.toInt());
    }

    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return drink;
    }

    final intValue = int.tryParse(text);
    if (intValue != null) {
      return _fromInt(intValue);
    }

    return switch (text.toLowerCase()) {
      'food' => food,
      'drink' => drink,
      _ => drink,
    };
  }

  static ProductType _fromInt(int value) {
    return switch (value) {
      1 => food,
      2 => drink,
      _ => drink,
    };
  }
}
