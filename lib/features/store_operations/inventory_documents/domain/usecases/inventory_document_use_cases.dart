import '../entities/inventory_document.dart';
import '../repositories/inventory_document_repository.dart';

class LoadInventoryImportsUseCase {
  final InventoryDocumentRepository _repository;
  const LoadInventoryImportsUseCase(this._repository);
  Future<InventoryDocumentPage> call({
    required int storeId,
    InventoryDocumentStatus? status,
    DateTime? from,
    DateTime? to,
    required int pageIndex,
    required int pageSize,
  }) => _repository.loadImports(
    storeId: storeId,
    status: status,
    from: from,
    to: to,
    pageIndex: pageIndex,
    pageSize: pageSize,
  );
}

class LoadInventoryDocumentUseCase {
  final InventoryDocumentRepository _repository;
  const LoadInventoryDocumentUseCase(this._repository);
  Future<InventoryDocument> call(int id) => _repository.loadDocument(id);
}

class LoadInventoryVendorsUseCase {
  final InventoryDocumentRepository _repository;
  const LoadInventoryVendorsUseCase(this._repository);
  Future<List<InventoryVendor>> call(int storeId, {String? keyword}) =>
      _repository.loadVendors(storeId, keyword: keyword);
}

class CreateInventoryVendorUseCase {
  final InventoryDocumentRepository _repository;
  const CreateInventoryVendorUseCase(this._repository);
  Future<InventoryVendor> call({
    required int storeId,
    required String name,
    required String phone,
    required String address,
  }) => _repository.createVendor(
    storeId: storeId,
    name: name,
    phone: phone,
    address: address,
  );
}

class LoadInventorySelectableItemsUseCase {
  final InventoryDocumentRepository _repository;
  const LoadInventorySelectableItemsUseCase(this._repository);
  Future<List<InventorySelectableItem>> call(int storeId) =>
      _repository.loadSelectableItems(storeId);
}

class CreateInventoryImportUseCase {
  final InventoryDocumentRepository _repository;
  const CreateInventoryImportUseCase(this._repository);
  Future<InventoryDocument> call({
    required int storeId,
    int? vendorId,
    String? note,
    required List<InventoryDocumentDraftItem> items,
  }) => _repository.createImport(
    storeId: storeId,
    vendorId: vendorId,
    note: note,
    items: items,
  );
}

class UpdateInventoryImportUseCase {
  final InventoryDocumentRepository _repository;
  const UpdateInventoryImportUseCase(this._repository);
  Future<InventoryDocument> call({
    required int documentId,
    required int storeId,
    int? vendorId,
    String? note,
    required List<InventoryDocumentDraftItem> items,
  }) => _repository.updateImport(
    documentId: documentId,
    storeId: storeId,
    vendorId: vendorId,
    note: note,
    items: items,
  );
}

class CompleteInventoryImportUseCase {
  final InventoryDocumentRepository _repository;
  const CompleteInventoryImportUseCase(this._repository);
  Future<InventoryDocument> call(int id) => _repository.completeImport(id);
}
