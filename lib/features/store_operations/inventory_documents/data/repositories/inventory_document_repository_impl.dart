import '../../domain/entities/inventory_document.dart';
import '../../domain/repositories/inventory_document_repository.dart';
import '../datasources/inventory_document_remote_data_source.dart';
import '../models/inventory_document_models.dart';

class InventoryDocumentRepositoryImpl implements InventoryDocumentRepository {
  final InventoryDocumentRemoteDataSource _remote;
  InventoryDocumentRepositoryImpl(this._remote);
  @override
  Future<InventoryDocumentPage> loadImports({
    required int storeId,
    InventoryDocumentStatus? status,
    DateTime? from,
    DateTime? to,
    required int pageIndex,
    required int pageSize,
  }) async => (await _remote.getImports(
    storeId: storeId,
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
  Future<InventoryDocument> createImport({
    required int storeId,
    int? vendorId,
    String? note,
    required List<InventoryDocumentDraftItem> items,
  }) async => (await _remote.create(
    InventoryDocumentRequestModel(
      storeId: storeId,
      vendorId: vendorId,
      note: note,
      items: items,
    ),
  )).toEntity();
  @override
  Future<InventoryDocument> updateImport({
    required int documentId,
    required int storeId,
    int? vendorId,
    String? note,
    required List<InventoryDocumentDraftItem> items,
  }) async => (await _remote.update(
    documentId,
    InventoryDocumentRequestModel(
      storeId: storeId,
      vendorId: vendorId,
      note: note,
      items: items,
    ),
  )).toEntity();
  @override
  Future<InventoryDocument> completeImport(int documentId) async =>
      (await _remote.complete(documentId)).toEntity();
}
