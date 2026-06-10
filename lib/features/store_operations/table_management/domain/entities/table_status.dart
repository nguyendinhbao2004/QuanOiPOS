enum TableStatus { available, occupied, reserved, disabled, unknown }

extension TableStatusX on TableStatus {
  String get label {
    return switch (this) {
      TableStatus.available => 'Còn trống',
      TableStatus.occupied => 'Đang dùng',
      TableStatus.reserved => 'Đã đặt',
      TableStatus.disabled => 'Ngưng hoạt động',
      TableStatus.unknown => 'Không rõ',
    };
  }

  bool get isAvailable => this == TableStatus.available;
  bool get isOccupied => this == TableStatus.occupied;
  bool get isDisabled => this == TableStatus.disabled;

  int get apiValue {
    return switch (this) {
      TableStatus.available => 1,
      TableStatus.occupied => 2,
      TableStatus.reserved => 3,
      TableStatus.disabled => 4,
      TableStatus.unknown => 0,
    };
  }
}
