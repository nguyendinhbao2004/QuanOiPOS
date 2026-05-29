enum TableStatus { available, occupied, reserved, unknown }

extension TableStatusX on TableStatus {
  String get label {
    return switch (this) {
      TableStatus.available => 'Còn trống',
      TableStatus.occupied => 'Đang dùng',
      TableStatus.reserved => 'Đã đặt',
      TableStatus.unknown => 'Không rõ',
    };
  }

  bool get isAvailable => this == TableStatus.available;
  bool get isOccupied => this == TableStatus.occupied;
}
