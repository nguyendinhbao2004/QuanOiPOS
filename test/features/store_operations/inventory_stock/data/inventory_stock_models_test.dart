import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/inventory_stock/data/models/inventory_stock_models.dart';
import 'package:quan_oi/features/store_operations/inventory_stock/domain/entities/inventory_stock.dart';

void main() {
  test('maps product stock response with inventory settings', () {
    final item = InventoryStockItemModel.fromJson({
      'id': 20,
      'storeId': 5,
      'name': 'Coca',
      'quantity': 4,
      'minimumStock': 2,
      'averageUnitCost': 7000,
      'lastImportUnitCost': 7500,
      'isTrackInventory': true,
      'inventoryDeductionMode': 'ProductOnly',
      'isLowStock': false,
      'isOutOfStock': false,
    }, InventoryStockItemType.product).toEntity();

    expect(item.type, InventoryStockItemType.product);
    expect(item.id, 20);
    expect(item.unit, 'sp');
    expect(item.quantity, 4);
    expect(item.minimumStock, 2);
    expect(item.averageUnitCost, 7000);
    expect(item.lastImportUnitCost, 7500);
    expect(item.isTrackInventory, isTrue);
    expect(item.inventoryDeductionMode, 'ProductOnly');
    expect(item.inventoryValue, 28000);
  });

  test('maps ingredient stock response and falls back for optional fields', () {
    final item = InventoryStockItemModel.fromJson({
      'id': 10,
      'storeId': 5,
      'name': 'Đường',
      'unit': 'g',
      'quantity': '1000.5',
      'minimumStock': '1200',
      'isLowStock': true,
      'isOutOfStock': false,
    }, InventoryStockItemType.ingredient).toEntity();

    expect(item.type, InventoryStockItemType.ingredient);
    expect(item.unit, 'g');
    expect(item.quantity, 1000.5);
    expect(item.minimumStock, 1200);
    expect(item.averageUnitCost, 0);
    expect(item.lastImportUnitCost, 0);
    expect(item.isTrackInventory, isFalse);
    expect(item.inventoryDeductionMode, isNull);
    expect(item.isLowStock, isTrue);
  });

  test('maps movement response', () {
    final movement = InventoryMovementModel.fromJson({
      'id': 99,
      'ingredientId': null,
      'productId': 20,
      'type': 'Export',
      'reason': 'Sale',
      'quantity': 2,
      'requestedQuantity': 3,
      'shortageQuantity': 1,
      'unitCost': 7000,
      'totalCost': 14000,
      'orderId': 12,
      'orderItemId': 15,
      'note': 'Paid order',
      'destinationName': 'Counter',
      'occurredAt': '2026-06-25T03:00:00Z',
    }).toEntity();

    expect(movement.id, 99);
    expect(movement.productId, 20);
    expect(movement.ingredientId, isNull);
    expect(movement.type, 'Export');
    expect(movement.reason, 'Sale');
    expect(movement.quantity, 2);
    expect(movement.requestedQuantity, 3);
    expect(movement.shortageQuantity, 1);
    expect(movement.totalCost, 14000);
    expect(movement.occurredAt, DateTime.parse('2026-06-25T03:00:00Z'));
  });
}
