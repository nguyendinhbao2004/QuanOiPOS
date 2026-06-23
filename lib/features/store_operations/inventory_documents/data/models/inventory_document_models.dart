import '../../domain/entities/inventory_document.dart';

class InventoryDocumentPageModel {
  final List<InventoryDocumentSummary> items;
  final int pageIndex, pageSize, totalCount, totalPages;
  const InventoryDocumentPageModel({
    required this.items,
    required this.pageIndex,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });
  factory InventoryDocumentPageModel.fromJson(Object? json) {
    final map = _map(json);
    final pagination = _map(map['pagination']);
    final rawItems = map['items'] is List ? map['items'] as List : const [];
    return InventoryDocumentPageModel(
      items: rawItems
          .map(
            (value) => InventoryDocumentSummaryModel.fromJson(value).toEntity(),
          )
          .toList(),
      pageIndex: _int(pagination['pageIndex'], 1),
      pageSize: _int(pagination['pageSize'], 20),
      totalCount: _int(pagination['totalCount']),
      totalPages: _int(pagination['totalPages'], 1),
    );
  }
  InventoryDocumentPage toEntity() => InventoryDocumentPage(
    items: items,
    pageIndex: pageIndex,
    pageSize: pageSize,
    totalCount: totalCount,
    totalPages: totalPages,
  );
}

class InventoryDocumentSummaryModel {
  final Map<String, dynamic> map;
  const InventoryDocumentSummaryModel._(this.map);
  factory InventoryDocumentSummaryModel.fromJson(Object? json) =>
      InventoryDocumentSummaryModel._(_map(json));
  InventoryDocumentSummary toEntity() => InventoryDocumentSummary(
    id: _int(map['id']),
    documentCode: _string(map['documentCode']),
    type: InventoryDocumentType.fromApi(map['type']),
    status: InventoryDocumentStatus.fromApi(map['status']),
    createdAt: _date(map['createdAt']),
    createdBy: _actor(map['createdBy']),
    vendor: _vendor(map['vendor']),
    totalAmount: _double(map['totalAmount']),
    note: _nullableString(map['note']),
  );
}

class InventoryDocumentModel {
  final Map<String, dynamic> map;
  const InventoryDocumentModel._(this.map);
  factory InventoryDocumentModel.fromJson(Object? json) =>
      InventoryDocumentModel._(_map(json));
  InventoryDocument toEntity() {
    final rawItems = map['items'] is List ? map['items'] as List : const [];
    return InventoryDocument(
      id: _int(map['id']),
      storeId: _int(map['storeId']),
      documentCode: _string(map['documentCode']),
      type: InventoryDocumentType.fromApi(map['type']),
      status: InventoryDocumentStatus.fromApi(map['status']),
      createdAt: _date(map['createdAt']),
      createdBy: _actor(map['createdBy']),
      completedAt: _date(map['completedAt']),
      completedBy: _actor(map['completedBy']),
      vendor: _vendor(map['vendor']),
      reason: InventoryIssueReason.fromApi(map['reason']),
      destinationName: _nullableString(map['destinationName']),
      note: _nullableString(map['note']),
      totalAmount: _double(map['totalAmount']),
      items: rawItems.map((value) => _item(value)).toList(),
    );
  }
}

class InventoryVendorModel {
  final Map<String, dynamic> map;
  const InventoryVendorModel._(this.map);
  factory InventoryVendorModel.fromJson(Object? json) =>
      InventoryVendorModel._(_map(json));
  static List<InventoryVendorModel> listFromJson(Object? json) => json is List
      ? json.map(InventoryVendorModel.fromJson).toList()
      : const [];
  InventoryVendor toEntity() => InventoryVendor(
    id: _int(map['id']),
    name: _string(map['name']),
    phone: _nullableString(map['phone']),
    address: _nullableString(map['address']),
  );
}

class CreateInventoryVendorRequestModel {
  final int storeId;
  final String name;
  final String phone;
  final String address;

  const CreateInventoryVendorRequestModel({
    required this.storeId,
    required this.name,
    required this.phone,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
    'storeId': storeId,
    'name': name,
    'phone': phone,
    'address': address,
  };
}

class InventoryItemModel {
  final Map<String, dynamic> map;
  final InventoryDocumentItemType type;
  const InventoryItemModel._(this.map, this.type);
  factory InventoryItemModel.fromJson(
    Object? json,
    InventoryDocumentItemType type,
  ) => InventoryItemModel._(_map(json), type);
  InventorySelectableItem toEntity() => InventorySelectableItem(
    type: type,
    id: _int(map['id']),
    name: _string(map['name']),
    unit: _string(map['unit']),
    currentQuantity: _double(map['quantity']),
    lastImportUnitCost: _double(map['lastImportUnitCost']),
  );
}

class InventoryDocumentRequestModel {
  final int storeId;
  final InventoryDocumentType type;
  final int? vendorId;
  final InventoryIssueReason? reason;
  final String? destinationName;
  final String? note;
  final List<InventoryDocumentDraftItem> items;
  const InventoryDocumentRequestModel({
    required this.storeId,
    required this.type,
    this.vendorId,
    this.reason,
    this.destinationName,
    this.note,
    required this.items,
  });
  Map<String, dynamic> toJson() => {
    'storeId': storeId,
    'type': type.apiValue,
    'vendorId': type == InventoryDocumentType.import ? vendorId : null,
    'reason': type == InventoryDocumentType.manualIssue
        ? reason?.apiValue
        : null,
    'destinationName': type == InventoryDocumentType.manualIssue
        ? destinationName
        : null,
    'note': note,
    'items': items
        .map(
          (item) => {
            'itemType': item.item.type.apiValue,
            'itemId': item.item.id,
            'quantity': item.quantity,
            'unitCost': type == InventoryDocumentType.manualIssue
                ? 0
                : item.unitCost,
          },
        )
        .toList(),
  };
}

List<InventoryShortageItem> shortagesFromJson(Object? json) {
  final map = _map(json);
  final raw = map['shortages'];
  if (raw is! List) return const [];
  return raw.map((value) {
    final item = _map(value);
    return InventoryShortageItem(
      itemType: InventoryDocumentItemType.fromApi(item['itemType']),
      itemId: _int(item['itemId']),
      itemName: _string(item['itemName']),
      unit: _string(item['unit']),
      currentQuantity: _double(item['currentQuantity']),
      requestedQuantity: _double(item['requestedQuantity']),
      shortageQuantity: _double(item['shortageQuantity']),
    );
  }).toList();
}

InventoryDocumentItem _item(Object? json) {
  final map = _map(json);
  final itemType = InventoryDocumentItemType.fromApi(map['itemType']);
  return InventoryDocumentItem(
    id: _int(map['id']),
    itemType: itemType,
    itemId: _documentItemId(map, itemType),
    itemName: _string(map['itemName']),
    unit: _string(map['unit']),
    currentQuantity: _double(map['currentQuantity']),
    quantity: _double(map['quantity']),
    unitCost: _double(map['unitCost']),
    lineTotal: _double(map['lineTotal']),
  );
}

int _documentItemId(Map<String, dynamic> map, InventoryDocumentItemType type) {
  final itemId = _int(map['itemId']);
  if (itemId > 0) return itemId;
  return type == InventoryDocumentItemType.product
      ? _int(map['productId'])
      : _int(map['ingredientId']);
}

InventoryVendor? _vendor(Object? json) {
  if (json == null) return null;
  final map = _map(json);
  return InventoryVendor(id: _int(map['id']), name: _string(map['name']));
}

InventoryDocumentActor? _actor(Object? json) {
  if (json == null) return null;
  final map = _map(json);
  return InventoryDocumentActor(
    accountId: _int(map['accountId']),
    displayName: _string(map['displayName']),
  );
}

Map<String, dynamic> _map(Object? value) => value is Map<String, dynamic>
    ? value
    : value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : <String, dynamic>{};
int _int(Object? value, [int fallback = 0]) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;
double _double(Object? value, [double fallback = 0]) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? fallback;
String _string(Object? value, [String fallback = '']) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());
