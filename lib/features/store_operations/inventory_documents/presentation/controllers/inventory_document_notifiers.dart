import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/inventory_document.dart';
import '../providers/inventory_document_providers.dart';
import 'inventory_document_state.dart';

class InventoryDocumentListNotifier
    extends
        AutoDisposeFamilyNotifier<
          InventoryDocumentListState,
          InventoryDocumentListArgs
        > {
  late InventoryDocumentListArgs _args;
  @override
  InventoryDocumentListState build(InventoryDocumentListArgs arg) {
    _args = arg;
    Future.microtask(load);
    return const InventoryDocumentListState.initial();
  }

  Future<void> load({int pageIndex = 1}) async {
    state = state.copyWith(
      status: InventoryDocumentLoadStatus.loading,
      clearError: true,
    );
    try {
      final page = await ref.read(loadInventoryDocumentsUseCaseProvider)(
        storeId: _args.storeId,
        type: _args.type,
        status: state.selectedStatus,
        from: state.from,
        to: state.to,
        pageIndex: pageIndex,
        pageSize: 20,
      );
      state = state.copyWith(
        status: InventoryDocumentLoadStatus.ready,
        page: page,
      );
    } catch (error) {
      state = state.copyWith(
        status: InventoryDocumentLoadStatus.error,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> setStatus(InventoryDocumentStatus? status) async {
    state = state.copyWith(selectedStatus: status, clearStatus: status == null);
    await load();
  }

  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    state = state.copyWith(from: from, to: to, clearDateRange: from == null);
    await load();
  }
}

class InventoryDocumentListArgs {
  final int storeId;
  final InventoryDocumentType type;
  const InventoryDocumentListArgs({required this.storeId, required this.type});
  @override
  bool operator ==(Object other) =>
      other is InventoryDocumentListArgs &&
      other.storeId == storeId &&
      other.type == type;
  @override
  int get hashCode => Object.hash(storeId, type);
}

class InventoryDocumentEditorNotifier
    extends
        AutoDisposeFamilyNotifier<
          InventoryDocumentEditorState,
          InventoryDocumentEditorArgs
        > {
  late InventoryDocumentEditorArgs _args;
  @override
  InventoryDocumentEditorState build(InventoryDocumentEditorArgs arg) {
    _args = arg;
    Future.microtask(load);
    return const InventoryDocumentEditorState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(
      status: InventoryDocumentLoadStatus.loading,
      clearError: true,
    );
    try {
      final vendorsFuture = _args.type == InventoryDocumentType.import
          ? ref.read(loadInventoryVendorsUseCaseProvider)(_args.storeId)
          : Future<List<InventoryVendor>>.value(const []);
      final itemsFuture = ref.read(loadInventorySelectableItemsUseCaseProvider)(
        _args.storeId,
      );
      final document = _args.documentId == null
          ? null
          : await ref.read(loadInventoryDocumentUseCaseProvider)(
              _args.documentId!,
            );
      final vendors = await vendorsFuture;
      final availableItems = await itemsFuture;
      state = state.copyWith(
        status: InventoryDocumentLoadStatus.ready,
        document: document,
        clearDocument: document == null,
        vendors: vendors,
        availableItems: availableItems,
        items:
            document?.items
                .map(
                  (item) => InventoryDocumentDraftItem(
                    item: InventorySelectableItem(
                      type: item.itemType,
                      id: item.itemId,
                      name: item.itemName,
                      unit: item.unit,
                      currentQuantity: item.currentQuantity,
                      lastImportUnitCost: item.unitCost,
                    ),
                    quantity: item.quantity,
                    unitCost: item.unitCost,
                  ),
                )
                .toList() ??
            const [],
        vendorId: document?.vendor?.id,
        clearVendor: document?.vendor == null,
        reason: document?.reason,
        clearReason: document?.reason == null,
        destinationName: document?.destinationName ?? '',
        note: document?.note ?? '',
        shortages: const {},
      );
    } catch (error) {
      state = state.copyWith(
        status: InventoryDocumentLoadStatus.error,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setVendor(int? vendorId) =>
      state = state.copyWith(vendorId: vendorId, clearVendor: vendorId == null);

  void setReason(InventoryIssueReason? reason) =>
      state = state.copyWith(reason: reason, clearReason: reason == null);

  void setDestinationName(String destinationName) =>
      state = state.copyWith(destinationName: destinationName);

  Future<InventoryVendor?> createVendor({
    required String name,
    required String phone,
    required String address,
  }) async {
    if (name.trim().isEmpty || phone.trim().isEmpty || address.trim().isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Vui lòng nhập đủ tên, số điện thoại và địa chỉ nhà cung cấp.',
      );
      return null;
    }
    try {
      final vendor = await ref.read(createInventoryVendorUseCaseProvider)(
        storeId: _args.storeId,
        name: name.trim(),
        phone: phone.trim(),
        address: address.trim(),
      );
      state = state.copyWith(
        vendors: [...state.vendors, vendor],
        vendorId: vendor.id,
        clearError: true,
      );
      return vendor;
    } catch (error) {
      state = state.copyWith(
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  void setNote(String note) => state = state.copyWith(note: note);
  void addItem(InventorySelectableItem item) {
    if (state.items.any(
      (line) => line.item.type == item.type && line.item.id == item.id,
    )) {
      return;
    }
    state = state.copyWith(
      items: [
        ...state.items,
        InventoryDocumentDraftItem(
          item: item,
          quantity: 1,
          unitCost: _args.type == InventoryDocumentType.manualIssue
              ? 0
              : item.lastImportUnitCost,
        ),
      ],
      shortages: const {},
    );
  }

  void updateItem(
    InventoryDocumentDraftItem item, {
    double? quantity,
    double? unitCost,
  }) {
    state = state.copyWith(
      items: state.items
          .map(
            (line) =>
                line.item.type == item.item.type && line.item.id == item.item.id
                ? line.copyWith(quantity: quantity, unitCost: unitCost)
                : line,
          )
          .toList(),
      shortages: const {},
    );
  }

  void removeItem(InventoryDocumentDraftItem item) => state = state.copyWith(
    items: state.items
        .where(
          (line) =>
              !(line.item.type == item.item.type &&
                  line.item.id == item.item.id),
        )
        .toList(),
    shortages: const {},
  );
  Future<InventoryDocument?> save() async {
    if (state.items.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Vui lòng chọn ít nhất một hàng hóa.',
      );
      return null;
    }
    if (state.items.any((item) => item.quantity <= 0 || item.unitCost < 0)) {
      state = state.copyWith(
        errorMessage: 'Số lượng phải lớn hơn 0 và đơn giá không được âm.',
      );
      return null;
    }
    if (_args.type == InventoryDocumentType.manualIssue) {
      if (state.reason == null) {
        state = state.copyWith(errorMessage: 'Vui lòng chọn lý do xuất kho.');
        return null;
      }
      if (state.note.trim().isEmpty) {
        state = state.copyWith(errorMessage: 'Vui lòng nhập ghi chú xuất kho.');
        return null;
      }
      if (state.reason == InventoryIssueReason.transferOut &&
          state.destinationName.trim().isEmpty) {
        state = state.copyWith(
          errorMessage: 'Vui lòng nhập nơi nhận khi chuyển chi nhánh.',
        );
        return null;
      }
    }
    if (state.items.any(
      (item) =>
          item.item.type == InventoryDocumentItemType.product &&
          item.quantity != item.quantity.roundToDouble(),
    )) {
      state = state.copyWith(
        errorMessage: 'Số lượng sản phẩm phải là số nguyên.',
      );
      return null;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final document = _args.documentId == null
          ? await ref.read(createInventoryDocumentUseCaseProvider)(
              storeId: _args.storeId,
              type: _args.type,
              vendorId: _args.type == InventoryDocumentType.import
                  ? state.vendorId
                  : null,
              reason: _args.type == InventoryDocumentType.manualIssue
                  ? state.reason
                  : null,
              destinationName: _args.type == InventoryDocumentType.manualIssue
                  ? state.destinationName.trim()
                  : null,
              note: state.note.trim().isEmpty ? null : state.note.trim(),
              items: state.items,
            )
          : await ref.read(updateInventoryDocumentUseCaseProvider)(
              documentId: _args.documentId!,
              storeId: _args.storeId,
              type: _args.type,
              vendorId: _args.type == InventoryDocumentType.import
                  ? state.vendorId
                  : null,
              reason: _args.type == InventoryDocumentType.manualIssue
                  ? state.reason
                  : null,
              destinationName: _args.type == InventoryDocumentType.manualIssue
                  ? state.destinationName.trim()
                  : null,
              note: state.note.trim().isEmpty ? null : state.note.trim(),
              items: state.items,
            );
      state = state.copyWith(document: document, isSaving: false);
      return document;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> complete() async {
    final id = state.document?.id;
    if (id == null) return false;
    state = state.copyWith(
      isCompleting: true,
      clearError: true,
      shortages: const {},
    );
    try {
      final document = await ref.read(completeInventoryDocumentUseCaseProvider)(
        id,
      );
      state = state.copyWith(document: document, isCompleting: false);
      return true;
    } on InventoryDocumentShortageException catch (error) {
      state = state.copyWith(
        isCompleting: false,
        shortages: {for (final item in error.shortages) item.key: item},
        errorMessage: error.message,
      );
      return false;
    } catch (error) {
      state = state.copyWith(
        isCompleting: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> cancel() async {
    final id = state.document?.id;
    if (id == null) return false;
    state = state.copyWith(isCancelling: true, clearError: true);
    try {
      final document = await ref.read(cancelInventoryDocumentUseCaseProvider)(
        id,
      );
      state = state.copyWith(document: document, isCancelling: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isCancelling: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

class InventoryDocumentEditorArgs {
  final int storeId;
  final InventoryDocumentType type;
  final int? documentId;
  const InventoryDocumentEditorArgs({
    required this.storeId,
    this.type = InventoryDocumentType.import,
    this.documentId,
  });
  @override
  bool operator ==(Object other) =>
      other is InventoryDocumentEditorArgs &&
      other.storeId == storeId &&
      other.type == type &&
      other.documentId == documentId;
  @override
  int get hashCode => Object.hash(storeId, type, documentId);
}
