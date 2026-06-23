import '../../domain/entities/inventory_document.dart';
import '../../domain/repositories/inventory_document_repository.dart';
import '../datasources/inventory_document_remote_data_source.dart';
import '../models/inventory_document_models.dart';

class InventoryDocumentRepositoryImpl implements InventoryDocumentRepository {
  final InventoryDocumentRemoteDataSource _remote;
  InventoryDocumentRepositoryImpl(this._remote);
  @override
  Future<InventoryDocumentPage> loadDocuments({
    required int storeId,
    required InventoryDocumentType type,
    InventoryDocumentStatus? status,
    DateTime? from,
    DateTime? to,
    required int pageIndex,
    required int pageSize,
  }) async => (await _remote.getDocuments(
    storeId: storeId,
    type: type,
    status: status,
    from: from,
    to: to,
    pageIndex: pageIndex,
    pageSize: pageSize,
  )).toEntity();
  @override
  Future<InventoryDocument> loadDocument(int id) async =>
      (await _remote.getDocument(id)).toEntity();
  @override
  Future<List<InventoryVendor>> loadVendors(
    int storeId, {
    String? keyword,
  }) async => (await _remote.getVendors(
    storeId,
    keyword: keyword,
  )).map((item) => item.toEntity()).toList();
  @override
  Future<InventoryVendor> createVendor({
    required int storeId,
    required String name,
    required String phone,
    required String address,
  }) async => (await _remote.createVendor(
    CreateInventoryVendorRequestModel(
      storeId: storeId,
      name: name,
      phone: phone,
      address: address,
    ),
  )).toEntity();
  @override
  Future<List<InventorySelectableItem>> loadSelectableItems(
    int storeId,
  ) async =>
      (await _remote.getItems(storeId)).map((item) => item.toEntity()).toList();
  @override
  Future<InventoryDocument> createDocument({
    required int storeId,
    required InventoryDocumentType type,
    int? vendorId,
    InventoryIssueReason? reason,
    String? destinationName,
    String? note,
    required List<InventoryDocumentDraftItem> items,
  }) async => (await _remote.create(
    InventoryDocumentRequestModel(
      storeId: storeId,
      type: type,
      vendorId: vendorId,
      reason: reason,
      destinationName: destinationName,
      note: note,
      items: items,
    ),
  )).toEntity();
  @override
  Future<InventoryDocument> updateDocument({
    required int documentId,
    required int storeId,
    required InventoryDocumentType type,
    int? vendorId,
    InventoryIssueReason? reason,
    String? destinationName,
    String? note,
    required List<InventoryDocumentDraftItem> items,
  }) async => (await _remote.update(
    documentId,
    InventoryDocumentRequestModel(
      storeId: storeId,
      type: type,
      vendorId: vendorId,
      reason: reason,
      destinationName: destinationName,
      note: note,
      items: items,
    ),
  )).toEntity();
  @override
  Future<InventoryDocument> completeDocument(int documentId) async =>
      (await _remote.complete(documentId)).toEntity();
  @override
  Future<InventoryDocument> cancelDocument(int documentId) async =>
      (await _remote.cancel(documentId)).toEntity();
}
