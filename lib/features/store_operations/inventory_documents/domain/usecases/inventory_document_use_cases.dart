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
  }) => _repository.loadDocuments(
    storeId: storeId,
    type: InventoryDocumentType.import,
    status: status,
    from: from,
    to: to,
    pageIndex: pageIndex,
    pageSize: pageSize,
  );
}

class LoadInventoryDocumentsUseCase {
  final InventoryDocumentRepository _repository;
  const LoadInventoryDocumentsUseCase(this._repository);
  Future<InventoryDocumentPage> call({
    required int storeId,
    required InventoryDocumentType type,
    InventoryDocumentStatus? status,
    DateTime? from,
    DateTime? to,
    required int pageIndex,
    required int pageSize,
  }) => _repository.loadDocuments(
    storeId: storeId,
    type: type,
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
  }) => _repository.createDocument(
    storeId: storeId,
    type: InventoryDocumentType.import,
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
  }) => _repository.updateDocument(
    documentId: documentId,
    storeId: storeId,
    type: InventoryDocumentType.import,
    vendorId: vendorId,
    note: note,
    items: items,
  );
}

class CompleteInventoryImportUseCase {
  final InventoryDocumentRepository _repository;
  const CompleteInventoryImportUseCase(this._repository);
  Future<InventoryDocument> call(int id) => _repository.completeDocument(id);
}

class CreateInventoryDocumentUseCase {
  final InventoryDocumentRepository _repository;
  const CreateInventoryDocumentUseCase(this._repository);
  Future<InventoryDocument> call({
    required int storeId,
    required InventoryDocumentType type,
    int? vendorId,
    InventoryIssueReason? reason,
    String? destinationName,
    String? note,
    required List<InventoryDocumentDraftItem> items,
  }) => _repository.createDocument(
    storeId: storeId,
    type: type,
    vendorId: vendorId,
    reason: reason,
    destinationName: destinationName,
    note: note,
    items: items,
  );
}

class UpdateInventoryDocumentUseCase {
  final InventoryDocumentRepository _repository;
  const UpdateInventoryDocumentUseCase(this._repository);
  Future<InventoryDocument> call({
    required int documentId,
    required int storeId,
    required InventoryDocumentType type,
    int? vendorId,
    InventoryIssueReason? reason,
    String? destinationName,
    String? note,
    required List<InventoryDocumentDraftItem> items,
  }) => _repository.updateDocument(
    documentId: documentId,
    storeId: storeId,
    type: type,
    vendorId: vendorId,
    reason: reason,
    destinationName: destinationName,
    note: note,
    items: items,
  );
}

class CompleteInventoryDocumentUseCase {
  final InventoryDocumentRepository _repository;
  const CompleteInventoryDocumentUseCase(this._repository);
  Future<InventoryDocument> call(int id) => _repository.completeDocument(id);
}

class CancelInventoryDocumentUseCase {
  final InventoryDocumentRepository _repository;
  const CancelInventoryDocumentUseCase(this._repository);
  Future<InventoryDocument> call(int id) => _repository.cancelDocument(id);
}
