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
  });
}
