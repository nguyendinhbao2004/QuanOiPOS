import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/inventory_document.dart';
import '../providers/inventory_document_providers.dart';
import 'inventory_document_state.dart';

class InventoryDocumentListNotifier
    extends AutoDisposeFamilyNotifier<InventoryDocumentListState, int> {
  late int _storeId;
  @override
  InventoryDocumentListState build(int arg) {
    _storeId = arg;
    Future.microtask(load);
    return const InventoryDocumentListState.initial();
  }

  Future<void> load({int pageIndex = 1}) async {
    state = state.copyWith(
      status: InventoryDocumentLoadStatus.loading,
      clearError: true,
    );
    try {
      final page = await ref.read(loadInventoryImportsUseCaseProvider)(
        storeId: _storeId,
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
      final vendorsFuture = ref.read(loadInventoryVendorsUseCaseProvider)(
        _args.storeId,
      );
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
          unitCost: item.lastImportUnitCost,
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
          ? await ref.read(createInventoryImportUseCaseProvider)(
              storeId: _args.storeId,
              vendorId: state.vendorId,
              note: state.note.trim().isEmpty ? null : state.note.trim(),
              items: state.items,
            )
          : await ref.read(updateInventoryImportUseCaseProvider)(
              documentId: _args.documentId!,
              storeId: _args.storeId,
              vendorId: state.vendorId,
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
      final document = await ref.read(completeInventoryImportUseCaseProvider)(
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
}

class InventoryDocumentEditorArgs {
  final int storeId;
  final int? documentId;
  const InventoryDocumentEditorArgs({required this.storeId, this.documentId});
  @override
  bool operator ==(Object other) =>
      other is InventoryDocumentEditorArgs &&
      other.storeId == storeId &&
      other.documentId == documentId;
  @override
  int get hashCode => Object.hash(storeId, documentId);
}
