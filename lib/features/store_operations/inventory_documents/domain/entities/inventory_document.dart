enum InventoryDocumentStatus {
  draft('Draft', 'Đang xử lý'),
  completed('Completed', 'Hoàn thành'),
  cancelled('Cancelled', 'Hủy');

  final String apiValue;
  final String label;
  const InventoryDocumentStatus(this.apiValue, this.label);

  static InventoryDocumentStatus fromApi(Object? value) =>
      InventoryDocumentStatus.values.firstWhere(
        (status) =>
            status.apiValue.toLowerCase() == value.toString().toLowerCase(),
        orElse: () => InventoryDocumentStatus.draft,
      );
}

enum InventoryDocumentType {
  import('Import', 'Nhập hàng'),
  manualIssue('ManualIssue', 'Xuất hàng');

  final String apiValue;
  final String label;
  const InventoryDocumentType(this.apiValue, this.label);

  static InventoryDocumentType fromApi(Object? value) =>
      InventoryDocumentType.values.firstWhere(
        (type) => type.apiValue.toLowerCase() == value.toString().toLowerCase(),
        orElse: () => InventoryDocumentType.import,
      );
}

enum InventoryIssueReason {
  internalUse('InternalUse', 'Dùng nội bộ'),
  transferOut('TransferOut', 'Chuyển chi nhánh'),
  otherIssue('OtherIssue', 'Khác');

  final String apiValue;
  final String label;
  const InventoryIssueReason(this.apiValue, this.label);

  static InventoryIssueReason? fromApi(Object? value) {
    if (value == null) return null;
    return InventoryIssueReason.values.firstWhere(
      (reason) =>
          reason.apiValue.toLowerCase() == value.toString().toLowerCase(),
      orElse: () => InventoryIssueReason.otherIssue,
    );
  }
}

enum InventoryDocumentItemType {
  ingredient('Ingredient', 'Nguyên liệu'),
  product('Product', 'Sản phẩm');

  final String apiValue;
  final String label;
  const InventoryDocumentItemType(this.apiValue, this.label);

  static InventoryDocumentItemType fromApi(Object? value) =>
      InventoryDocumentItemType.values.firstWhere(
        (type) => type.apiValue.toLowerCase() == value.toString().toLowerCase(),
        orElse: () => InventoryDocumentItemType.ingredient,
      );
}

class InventoryVendor {
  final int id;
  final String name;
  final String? phone;
  final String? address;
  const InventoryVendor({
    required this.id,
    required this.name,
    this.phone,
    this.address,
  });
}

class InventoryDocumentActor {
  final int accountId;
  final String displayName;
  const InventoryDocumentActor({
    required this.accountId,
    required this.displayName,
  });
}

class InventorySelectableItem {
  final InventoryDocumentItemType type;
  final int id;
  final String name;
  final String unit;
  final double currentQuantity;
  final double lastImportUnitCost;
  const InventorySelectableItem({
    required this.type,
    required this.id,
    required this.name,
    required this.unit,
    required this.currentQuantity,
    required this.lastImportUnitCost,
  });
}

class InventoryDocumentItem {
  final int id;
  final InventoryDocumentItemType itemType;
  final int itemId;
  final String itemName;
  final String unit;
  final double currentQuantity;
  final double quantity;
  final double unitCost;
  final double lineTotal;
  const InventoryDocumentItem({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.currentQuantity,
    required this.quantity,
    required this.unitCost,
    required this.lineTotal,
  });
}

class InventoryDocumentSummary {
  final int id;
  final String documentCode;
  final InventoryDocumentType type;
  final InventoryDocumentStatus status;
  final DateTime? createdAt;
  final InventoryDocumentActor? createdBy;
  final InventoryVendor? vendor;
  final double totalAmount;
  final String? note;
  const InventoryDocumentSummary({
    required this.id,
    required this.documentCode,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.vendor,
    required this.totalAmount,
    required this.note,
  });
}

class InventoryDocument {
  final int id;
  final int storeId;
  final String documentCode;
  final InventoryDocumentType type;
  final InventoryDocumentStatus status;
  final DateTime? createdAt;
  final InventoryDocumentActor? createdBy;
  final DateTime? completedAt;
  final InventoryDocumentActor? completedBy;
  final InventoryVendor? vendor;
  final InventoryIssueReason? reason;
  final String? destinationName;
  final String? note;
  final double totalAmount;
  final List<InventoryDocumentItem> items;
  const InventoryDocument({
    required this.id,
    required this.storeId,
    required this.documentCode,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.completedAt,
    required this.completedBy,
    required this.vendor,
    required this.reason,
    required this.destinationName,
    required this.note,
    required this.totalAmount,
    required this.items,
  });
}

class InventoryDocumentPage {
  final List<InventoryDocumentSummary> items;
  final int pageIndex;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  const InventoryDocumentPage({
    required this.items,
    required this.pageIndex,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });
}

class InventoryDocumentDraftItem {
  final InventorySelectableItem item;
  final double quantity;
  final double unitCost;
  const InventoryDocumentDraftItem({
    required this.item,
    required this.quantity,
    required this.unitCost,
  });
  double get lineTotal => quantity * unitCost;
  InventoryDocumentDraftItem copyWith({double? quantity, double? unitCost}) =>
      InventoryDocumentDraftItem(
        item: item,
        quantity: quantity ?? this.quantity,
        unitCost: unitCost ?? this.unitCost,
      );
}

class InventoryShortageItem {
  final InventoryDocumentItemType itemType;
  final int itemId;
  final String itemName;
  final String unit;
  final double currentQuantity;
  final double requestedQuantity;
  final double shortageQuantity;
  const InventoryShortageItem({
    required this.itemType,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.currentQuantity,
    required this.requestedQuantity,
    required this.shortageQuantity,
  });
  String get key => '${itemType.apiValue}:$itemId';
}

class InventoryDocumentShortageException implements Exception {
  final String message;
  final List<InventoryShortageItem> shortages;
  const InventoryDocumentShortageException(this.message, this.shortages);
  @override
  String toString() => message;
}
