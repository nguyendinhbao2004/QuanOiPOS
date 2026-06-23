import '../entities/inventory_document.dart';

abstract class InventoryDocumentRepository {
  Future<InventoryDocumentPage> loadDocuments({
    required int storeId,
    required InventoryDocumentType type,
    InventoryDocumentStatus? status,
    DateTime? from,
    DateTime? to,
    required int pageIndex,
    required int pageSize,
  });
  Future<InventoryDocument> loadDocument(int id);
  Future<List<InventoryVendor>> loadVendors(int storeId, {String? keyword});
  Future<InventoryVendor> createVendor({
    required int storeId,
    required String name,
    required String phone,
    required String address,
  });
  Future<List<InventorySelectableItem>> loadSelectableItems(int storeId);
  Future<InventoryDocument> createDocument({
    required int storeId,
    required InventoryDocumentType type,
    int? vendorId,
    InventoryIssueReason? reason,
    String? destinationName,
    String? note,
    required List<InventoryDocumentDraftItem> items,
  });
  Future<InventoryDocument> updateDocument({
    required int documentId,
    required int storeId,
    required InventoryDocumentType type,
    int? vendorId,
    InventoryIssueReason? reason,
    String? destinationName,
    String? note,
    required List<InventoryDocumentDraftItem> items,
  });
  Future<InventoryDocument> completeDocument(int documentId);
  Future<InventoryDocument> cancelDocument(int documentId);
}
