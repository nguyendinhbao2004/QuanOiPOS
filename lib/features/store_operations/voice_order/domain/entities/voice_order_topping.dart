class VoiceOrderTopping {
  final int? id;
  final String name;
  final int quantity;

  const VoiceOrderTopping({
    this.id,
    required this.name,
    required this.quantity,
  });

  VoiceOrderTopping copyWith({
    Object? id = _unchanged,
    String? name,
    int? quantity,
  }) {
    return VoiceOrderTopping(
      id: id == _unchanged ? this.id : id as int?,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
    );
  }
}

const Object _unchanged = Object();
