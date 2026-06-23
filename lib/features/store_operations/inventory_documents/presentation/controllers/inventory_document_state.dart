import '../../domain/entities/inventory_document.dart';

enum InventoryDocumentLoadStatus { initial, loading, ready, error }

class InventoryDocumentListState {
  final InventoryDocumentLoadStatus status;
  final InventoryDocumentPage? page;
  final InventoryDocumentStatus? selectedStatus;
  final DateTime? from;
  final DateTime? to;
  final String? errorMessage;
  const InventoryDocumentListState({
    required this.status,
    this.page,
    this.selectedStatus,
    this.from,
    this.to,
    this.errorMessage,
  });
  const InventoryDocumentListState.initial()
    : status = InventoryDocumentLoadStatus.initial,
      page = null,
      selectedStatus = null,
      from = null,
      to = null,
      errorMessage = null;
  InventoryDocumentListState copyWith({
    InventoryDocumentLoadStatus? status,
    InventoryDocumentPage? page,
    InventoryDocumentStatus? selectedStatus,
    bool clearStatus = false,
    DateTime? from,
    DateTime? to,
    bool clearDateRange = false,
    String? errorMessage,
    bool clearError = false,
  }) => InventoryDocumentListState(
    status: status ?? this.status,
    page: page ?? this.page,
    selectedStatus: clearStatus
        ? null
        : (selectedStatus ?? this.selectedStatus),
    from: clearDateRange ? null : (from ?? this.from),
    to: clearDateRange ? null : (to ?? this.to),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class InventoryDocumentEditorState {
  final InventoryDocumentLoadStatus status;
  final InventoryDocument? document;
  final List<InventoryVendor> vendors;
  final List<InventorySelectableItem> availableItems;
  final List<InventoryDocumentDraftItem> items;
  final int? vendorId;
  final InventoryIssueReason? reason;
  final String destinationName;
  final String note;
  final bool isSaving;
  final bool isCompleting;
  final bool isCancelling;
  final Map<String, InventoryShortageItem> shortages;
  final String? errorMessage;
  const InventoryDocumentEditorState({
    required this.status,
    this.document,
    this.vendors = const [],
    this.availableItems = const [],
    this.items = const [],
    this.vendorId,
    this.reason,
    this.destinationName = '',
    this.note = '',
    this.isSaving = false,
    this.isCompleting = false,
    this.isCancelling = false,
    this.shortages = const {},
    this.errorMessage,
  });
  const InventoryDocumentEditorState.initial()
    : status = InventoryDocumentLoadStatus.initial,
      document = null,
      vendors = const [],
      availableItems = const [],
      items = const [],
      vendorId = null,
      reason = null,
      destinationName = '',
      note = '',
      isSaving = false,
      isCompleting = false,
      isCancelling = false,
      shortages = const {},
      errorMessage = null;
  bool get isDraft =>
      document == null || document!.status == InventoryDocumentStatus.draft;
  double get totalAmount =>
      items.fold(0, (total, item) => total + item.lineTotal);
  InventoryDocumentEditorState copyWith({
    InventoryDocumentLoadStatus? status,
    InventoryDocument? document,
    bool clearDocument = false,
    List<InventoryVendor>? vendors,
    List<InventorySelectableItem>? availableItems,
    List<InventoryDocumentDraftItem>? items,
    int? vendorId,
    bool clearVendor = false,
    InventoryIssueReason? reason,
    bool clearReason = false,
    String? destinationName,
    String? note,
    bool? isSaving,
    bool? isCompleting,
    bool? isCancelling,
    Map<String, InventoryShortageItem>? shortages,
    String? errorMessage,
    bool clearError = false,
  }) => InventoryDocumentEditorState(
    status: status ?? this.status,
    document: clearDocument ? null : (document ?? this.document),
    vendors: vendors ?? this.vendors,
    availableItems: availableItems ?? this.availableItems,
    items: items ?? this.items,
    vendorId: clearVendor ? null : (vendorId ?? this.vendorId),
    reason: clearReason ? null : (reason ?? this.reason),
    destinationName: destinationName ?? this.destinationName,
    note: note ?? this.note,
    isSaving: isSaving ?? this.isSaving,
    isCompleting: isCompleting ?? this.isCompleting,
    isCancelling: isCancelling ?? this.isCancelling,
    shortages: shortages ?? this.shortages,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}
