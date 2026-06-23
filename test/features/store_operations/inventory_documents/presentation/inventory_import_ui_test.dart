import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/inventory_documents/domain/entities/inventory_document.dart';
import 'package:quan_oi/features/store_operations/inventory_documents/data/models/inventory_document_models.dart';
import 'package:quan_oi/features/store_operations/inventory_documents/presentation/pages/inventory_import_item_picker_page.dart';

void main() {
  group('Inventory import UI', () {
    test('keeps backend statuses while using the approved labels', () {
      expect(InventoryDocumentStatus.draft.apiValue, 'Draft');
      expect(InventoryDocumentStatus.draft.label, 'Đang xử lý');
      expect(InventoryDocumentStatus.cancelled.apiValue, 'Cancelled');
      expect(InventoryDocumentStatus.cancelled.label, 'Hủy');
    });

    test('formats stock copy by item type', () {
      const product = InventorySelectableItem(
        type: InventoryDocumentItemType.product,
        id: 10,
        name: 'Coca Cola lon',
        unit: '',
        currentQuantity: 24,
        lastImportUnitCost: 12000,
      );
      const ingredient = InventorySelectableItem(
        type: InventoryDocumentItemType.ingredient,
        id: 10,
        name: 'Trà ô long',
        unit: 'g',
        currentQuantity: 850,
        lastImportUnitCost: 125,
      );

      expect(inventorySelectableItemStockLabel(product), 'Còn: 24');
      expect(inventorySelectableItemStockLabel(ingredient), 'Còn: 850 g');
    });

    test('maps last import unit cost for products and ingredients', () {
      final product = InventoryItemModel.fromJson(const {
        'id': 20,
        'name': 'Coca Cola lon',
        'quantity': 24,
        'lastImportUnitCost': 12000,
      }, InventoryDocumentItemType.product).toEntity();
      final ingredient = InventoryItemModel.fromJson(const {
        'id': 10,
        'name': 'Trà ô long',
        'unit': 'g',
        'quantity': 850,
        'lastImportUnitCost': 125,
      }, InventoryDocumentItemType.ingredient).toEntity();

      expect(product.lastImportUnitCost, 12000);
      expect(ingredient.lastImportUnitCost, 125);
    });

    test('builds import document payload with vendor and unit cost', () {
      final request = InventoryDocumentRequestModel(
        storeId: 1,
        type: InventoryDocumentType.import,
        vendorId: 3,
        note: 'Nhập hàng đầu tuần',
        items: const [
          InventoryDocumentDraftItem(
            item: InventorySelectableItem(
              type: InventoryDocumentItemType.ingredient,
              id: 10,
              name: 'Trà ô long',
              unit: 'g',
              currentQuantity: 850,
              lastImportUnitCost: 125,
            ),
            quantity: 500,
            unitCost: 125,
          ),
        ],
      ).toJson();

      expect(request['type'], 'Import');
      expect(request['vendorId'], 3);
      expect(request['reason'], isNull);
      expect(request['destinationName'], isNull);
      expect((request['items'] as List).single['unitCost'], 125);
    });

    test('builds manual issue payload with reason and zero unit cost', () {
      final request = InventoryDocumentRequestModel(
        storeId: 1,
        type: InventoryDocumentType.manualIssue,
        vendorId: 3,
        reason: InventoryIssueReason.transferOut,
        destinationName: 'Chi nhánh 2',
        note: 'Điều chuyển cuối ngày',
        items: const [
          InventoryDocumentDraftItem(
            item: InventorySelectableItem(
              type: InventoryDocumentItemType.product,
              id: 20,
              name: 'Coca Cola lon',
              unit: 'cái',
              currentQuantity: 23,
              lastImportUnitCost: 12000,
            ),
            quantity: 2,
            unitCost: 12000,
          ),
        ],
      ).toJson();

      expect(request['type'], 'ManualIssue');
      expect(request['vendorId'], isNull);
      expect(request['reason'], 'TransferOut');
      expect(request['destinationName'], 'Chi nhánh 2');
      expect((request['items'] as List).single['unitCost'], 0);
    });

    test('maps document item ids from ingredientId and productId fields', () {
      final document = InventoryDocumentModel.fromJson(const {
        'id': 101,
        'storeId': 1,
        'documentCode': 'XK-000001',
        'type': 'ManualIssue',
        'status': 'Draft',
        'items': [
          {
            'id': 1001,
            'itemType': 'Ingredient',
            'ingredientId': 10,
            'productId': null,
            'itemName': 'Trà ô long',
            'unit': 'g',
            'currentQuantity': 850,
            'quantity': 500,
            'unitCost': 0,
            'lineTotal': 0,
          },
          {
            'id': 1002,
            'itemType': 'Product',
            'ingredientId': null,
            'productId': 20,
            'itemName': 'Coca Cola lon',
            'unit': 'cái',
            'currentQuantity': 23,
            'quantity': 2,
            'unitCost': 0,
            'lineTotal': 0,
          },
        ],
      }).toEntity();

      expect(document.type, InventoryDocumentType.manualIssue);
      expect(document.items.first.itemId, 10);
      expect(document.items.last.itemId, 20);
    });

    test('maps shortage key by item type and item id', () {
      final shortages = shortagesFromJson(const {
        'shortages': [
          {
            'itemType': 'Ingredient',
            'itemId': 10,
            'itemName': 'Trà ô long',
            'unit': 'g',
            'currentQuantity': 300,
            'requestedQuantity': 500,
            'shortageQuantity': 200,
          },
        ],
      });

      expect(shortages.single.key, 'Ingredient:10');
    });
  });
}
