import '../../domain/entities/business_report.dart';

class BusinessReportModel {
  final int id;
  final int storeId;
  final int type;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String content;
  final BusinessReportMetricsModel metrics;
  final DateTime? createdAt;

  const BusinessReportModel({
    required this.id,
    required this.storeId,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.content,
    required this.metrics,
    required this.createdAt,
  });

  factory BusinessReportModel.fromJson(Object? json) {
    final map = _asMap(json);
    return BusinessReportModel(
      id: _intValue(map['id'] ?? map['Id']),
      storeId: _intValue(map['storeId'] ?? map['StoreId']),
      type: _intValue(map['type'] ?? map['Type'], fallback: 3),
      fromDate: _dateValue(map['fromDate'] ?? map['FromDate']),
      toDate: _dateValue(map['toDate'] ?? map['ToDate']),
      content: _stringValue(map['content'] ?? map['Content']),
      metrics: BusinessReportMetricsModel.fromJson(
        map['metrics'] ?? map['Metrics'],
      ),
      createdAt: _dateValue(map['createdAt'] ?? map['CreatedAt']),
    );
  }

  BusinessReport toEntity() {
    return BusinessReport(
      id: id,
      storeId: storeId,
      type: type,
      fromDate: fromDate,
      toDate: toDate,
      content: content,
      metrics: metrics.toEntity(),
      createdAt: createdAt,
    );
  }
}

class BusinessReportMetricsModel {
  final RevenueSummaryModel revenueSummary;
  final ProfitSummaryModel profitSummary;
  final PurchaseSummaryModel purchaseSummary;
  final List<TopProductMetricModel> topProducts;
  final List<HourlyOrderMetricModel> hourlyOrders;
  final List<HourlyProductSaleMetricModel> hourlyProductSales;
  final InventorySummaryModel inventorySummary;
  final List<InventoryRecommendationModel> inventoryRecommendations;

  const BusinessReportMetricsModel({
    required this.revenueSummary,
    required this.profitSummary,
    required this.purchaseSummary,
    required this.topProducts,
    required this.hourlyOrders,
    required this.hourlyProductSales,
    required this.inventorySummary,
    required this.inventoryRecommendations,
  });

  factory BusinessReportMetricsModel.fromJson(Object? json) {
    final map = _asMap(json);
    return BusinessReportMetricsModel(
      revenueSummary: RevenueSummaryModel.fromJson(
        map['revenueSummary'] ?? map['RevenueSummary'],
      ),
      profitSummary: ProfitSummaryModel.fromJson(
        map['profitSummary'] ?? map['ProfitSummary'],
      ),
      purchaseSummary: PurchaseSummaryModel.fromJson(
        map['purchaseSummary'] ?? map['PurchaseSummary'],
      ),
      topProducts: _listFromJson(
        map['topProducts'] ?? map['TopProducts'],
        TopProductMetricModel.fromJson,
      ),
      hourlyOrders: _listFromJson(
        map['hourlyOrders'] ?? map['HourlyOrders'],
        HourlyOrderMetricModel.fromJson,
      ),
      hourlyProductSales: _listFromJson(
        map['hourlyProductSales'] ?? map['HourlyProductSales'],
        HourlyProductSaleMetricModel.fromJson,
      ),
      inventorySummary: InventorySummaryModel.fromJson(
        map['inventorySummary'] ?? map['InventorySummary'],
      ),
      inventoryRecommendations: _listFromJson(
        map['inventoryRecommendations'] ?? map['InventoryRecommendations'],
        InventoryRecommendationModel.fromJson,
      ),
    );
  }

  BusinessReportMetrics toEntity() {
    return BusinessReportMetrics(
      revenueSummary: revenueSummary.toEntity(),
      profitSummary: profitSummary.toEntity(),
      purchaseSummary: purchaseSummary.toEntity(),
      topProducts: topProducts.map((item) => item.toEntity()).toList(),
      hourlyOrders: hourlyOrders.map((item) => item.toEntity()).toList(),
      hourlyProductSales: hourlyProductSales
          .map((item) => item.toEntity())
          .toList(),
      inventorySummary: inventorySummary.toEntity(),
      inventoryRecommendations: inventoryRecommendations
          .map((item) => item.toEntity())
          .toList(),
    );
  }
}

class RevenueSummaryModel {
  final double totalRevenue;
  final double paidRevenue;
  final int completedOrderCount;
  final int cancelledOrderCount;
  final double averageOrderValue;

  const RevenueSummaryModel({
    required this.totalRevenue,
    required this.paidRevenue,
    required this.completedOrderCount,
    required this.cancelledOrderCount,
    required this.averageOrderValue,
  });

  factory RevenueSummaryModel.fromJson(Object? json) {
    final map = _asMap(json);
    return RevenueSummaryModel(
      totalRevenue: _doubleValue(map['totalRevenue'] ?? map['TotalRevenue']),
      paidRevenue: _doubleValue(map['paidRevenue'] ?? map['PaidRevenue']),
      completedOrderCount: _intValue(
        map['completedOrderCount'] ?? map['CompletedOrderCount'],
      ),
      cancelledOrderCount: _intValue(
        map['cancelledOrderCount'] ?? map['CancelledOrderCount'],
      ),
      averageOrderValue: _doubleValue(
        map['averageOrderValue'] ?? map['AverageOrderValue'],
      ),
    );
  }

  RevenueSummary toEntity() {
    return RevenueSummary(
      totalRevenue: totalRevenue,
      paidRevenue: paidRevenue,
      completedOrderCount: completedOrderCount,
      cancelledOrderCount: cancelledOrderCount,
      averageOrderValue: averageOrderValue,
    );
  }
}

class ProfitSummaryModel {
  final double totalCost;
  final double grossProfit;
  final double grossProfitMargin;

  const ProfitSummaryModel({
    required this.totalCost,
    required this.grossProfit,
    required this.grossProfitMargin,
  });

  factory ProfitSummaryModel.fromJson(Object? json) {
    final map = _asMap(json);
    return ProfitSummaryModel(
      totalCost: _doubleValue(map['totalCost'] ?? map['TotalCost']),
      grossProfit: _doubleValue(map['grossProfit'] ?? map['GrossProfit']),
      grossProfitMargin: _doubleValue(
        map['grossProfitMargin'] ?? map['GrossProfitMargin'],
      ),
    );
  }

  ProfitSummary toEntity() {
    return ProfitSummary(
      totalCost: totalCost,
      grossProfit: grossProfit,
      grossProfitMargin: grossProfitMargin,
    );
  }
}

class PurchaseSummaryModel {
  final double totalPurchaseCost;
  final int purchaseMovementCount;

  const PurchaseSummaryModel({
    required this.totalPurchaseCost,
    required this.purchaseMovementCount,
  });

  factory PurchaseSummaryModel.fromJson(Object? json) {
    final map = _asMap(json);
    return PurchaseSummaryModel(
      totalPurchaseCost: _doubleValue(
        map['totalPurchaseCost'] ?? map['TotalPurchaseCost'],
      ),
      purchaseMovementCount: _intValue(
        map['purchaseMovementCount'] ?? map['PurchaseMovementCount'],
      ),
    );
  }

  PurchaseSummary toEntity() {
    return PurchaseSummary(
      totalPurchaseCost: totalPurchaseCost,
      purchaseMovementCount: purchaseMovementCount,
    );
  }
}

class TopProductMetricModel {
  final int productId;
  final String productName;
  final double quantitySold;
  final double revenue;
  final double cost;
  final double grossProfit;
  final double grossProfitMargin;

  const TopProductMetricModel({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
    required this.cost,
    required this.grossProfit,
    required this.grossProfitMargin,
  });

  factory TopProductMetricModel.fromJson(Object? json) {
    final map = _asMap(json);
    return TopProductMetricModel(
      productId: _intValue(map['productId'] ?? map['ProductId']),
      productName: _stringValue(map['productName'] ?? map['ProductName']),
      quantitySold: _doubleValue(map['quantitySold'] ?? map['QuantitySold']),
      revenue: _doubleValue(map['revenue'] ?? map['Revenue']),
      cost: _doubleValue(map['cost'] ?? map['Cost']),
      grossProfit: _doubleValue(map['grossProfit'] ?? map['GrossProfit']),
      grossProfitMargin: _doubleValue(
        map['grossProfitMargin'] ?? map['GrossProfitMargin'],
      ),
    );
  }

  TopProductMetric toEntity() {
    return TopProductMetric(
      productId: productId,
      productName: productName,
      quantitySold: quantitySold,
      revenue: revenue,
      cost: cost,
      grossProfit: grossProfit,
      grossProfitMargin: grossProfitMargin,
    );
  }
}

class HourlyOrderMetricModel {
  final int hour;
  final int orderCount;
  final double revenue;

  const HourlyOrderMetricModel({
    required this.hour,
    required this.orderCount,
    required this.revenue,
  });

  factory HourlyOrderMetricModel.fromJson(Object? json) {
    final map = _asMap(json);
    return HourlyOrderMetricModel(
      hour: _intValue(map['hour'] ?? map['Hour']),
      orderCount: _intValue(map['orderCount'] ?? map['OrderCount']),
      revenue: _doubleValue(map['revenue'] ?? map['Revenue']),
    );
  }

  HourlyOrderMetric toEntity() {
    return HourlyOrderMetric(
      hour: hour,
      orderCount: orderCount,
      revenue: revenue,
    );
  }
}

class HourlyProductSaleMetricModel {
  final int hour;
  final int productId;
  final String productName;
  final double quantitySold;
  final double revenue;
  final double grossProfit;

  const HourlyProductSaleMetricModel({
    required this.hour,
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
    required this.grossProfit,
  });

  factory HourlyProductSaleMetricModel.fromJson(Object? json) {
    final map = _asMap(json);
    return HourlyProductSaleMetricModel(
      hour: _intValue(map['hour'] ?? map['Hour']),
      productId: _intValue(map['productId'] ?? map['ProductId']),
      productName: _stringValue(map['productName'] ?? map['ProductName']),
      quantitySold: _doubleValue(map['quantitySold'] ?? map['QuantitySold']),
      revenue: _doubleValue(map['revenue'] ?? map['Revenue']),
      grossProfit: _doubleValue(map['grossProfit'] ?? map['GrossProfit']),
    );
  }

  HourlyProductSaleMetric toEntity() {
    return HourlyProductSaleMetric(
      hour: hour,
      productId: productId,
      productName: productName,
      quantitySold: quantitySold,
      revenue: revenue,
      grossProfit: grossProfit,
    );
  }
}

class InventorySummaryModel {
  final int lowStockCount;
  final int outOfStockCount;
  final int missingRecipeProductCount;
  final List<InventoryAttentionItemModel> lowStockItems;
  final List<InventoryAttentionItemModel> outOfStockItems;

  const InventorySummaryModel({
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.missingRecipeProductCount,
    required this.lowStockItems,
    required this.outOfStockItems,
  });

  factory InventorySummaryModel.fromJson(Object? json) {
    final map = _asMap(json);
    return InventorySummaryModel(
      lowStockCount: _intValue(map['lowStockCount'] ?? map['LowStockCount']),
      outOfStockCount: _intValue(
        map['outOfStockCount'] ?? map['OutOfStockCount'],
      ),
      missingRecipeProductCount: _intValue(
        map['missingRecipeProductCount'] ?? map['MissingRecipeProductCount'],
      ),
      lowStockItems: _listFromJson(
        map['lowStockItems'] ?? map['LowStockItems'],
        InventoryAttentionItemModel.fromJson,
      ),
      outOfStockItems: _listFromJson(
        map['outOfStockItems'] ?? map['OutOfStockItems'],
        InventoryAttentionItemModel.fromJson,
      ),
    );
  }

  InventorySummary toEntity() {
    return InventorySummary(
      lowStockCount: lowStockCount,
      outOfStockCount: outOfStockCount,
      missingRecipeProductCount: missingRecipeProductCount,
      lowStockItems: lowStockItems.map((item) => item.toEntity()).toList(),
      outOfStockItems: outOfStockItems.map((item) => item.toEntity()).toList(),
    );
  }
}

class InventoryAttentionItemModel {
  final String itemType;
  final int itemId;
  final String itemName;
  final double quantity;
  final String unit;
  final double minimumStock;

  const InventoryAttentionItemModel({
    required this.itemType,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.minimumStock,
  });

  factory InventoryAttentionItemModel.fromJson(Object? json) {
    final map = _asMap(json);
    return InventoryAttentionItemModel(
      itemType: _stringValue(map['itemType'] ?? map['ItemType']),
      itemId: _intValue(map['itemId'] ?? map['ItemId']),
      itemName: _stringValue(map['itemName'] ?? map['ItemName']),
      quantity: _doubleValue(map['quantity'] ?? map['Quantity']),
      unit: _stringValue(map['unit'] ?? map['Unit']),
      minimumStock: _doubleValue(map['minimumStock'] ?? map['MinimumStock']),
    );
  }

  InventoryAttentionItem toEntity() {
    return InventoryAttentionItem(
      itemType: itemType,
      itemId: itemId,
      itemName: itemName,
      quantity: quantity,
      unit: unit,
      minimumStock: minimumStock,
    );
  }
}

class InventoryRecommendationModel {
  final String recommendationType;
  final String itemType;
  final int itemId;
  final String itemName;
  final double currentQuantity;
  final String unit;
  final double minimumStock;
  final double consumedQuantity;
  final double importedQuantity;
  final String reason;

  const InventoryRecommendationModel({
    required this.recommendationType,
    required this.itemType,
    required this.itemId,
    required this.itemName,
    required this.currentQuantity,
    required this.unit,
    required this.minimumStock,
    required this.consumedQuantity,
    required this.importedQuantity,
    required this.reason,
  });

  factory InventoryRecommendationModel.fromJson(Object? json) {
    final map = _asMap(json);
    return InventoryRecommendationModel(
      recommendationType: _stringValue(
        map['recommendationType'] ?? map['RecommendationType'],
      ),
      itemType: _stringValue(map['itemType'] ?? map['ItemType']),
      itemId: _intValue(map['itemId'] ?? map['ItemId']),
      itemName: _stringValue(map['itemName'] ?? map['ItemName']),
      currentQuantity: _doubleValue(
        map['currentQuantity'] ?? map['CurrentQuantity'],
      ),
      unit: _stringValue(map['unit'] ?? map['Unit']),
      minimumStock: _doubleValue(map['minimumStock'] ?? map['MinimumStock']),
      consumedQuantity: _doubleValue(
        map['consumedQuantity'] ?? map['ConsumedQuantity'],
      ),
      importedQuantity: _doubleValue(
        map['importedQuantity'] ?? map['ImportedQuantity'],
      ),
      reason: _stringValue(map['reason'] ?? map['Reason']),
    );
  }

  InventoryRecommendation toEntity() {
    return InventoryRecommendation(
      recommendationType: recommendationType,
      itemType: itemType,
      itemId: itemId,
      itemName: itemName,
      currentQuantity: currentQuantity,
      unit: unit,
      minimumStock: minimumStock,
      consumedQuantity: consumedQuantity,
      importedQuantity: importedQuantity,
      reason: reason,
    );
  }
}

Map<String, dynamic> _asMap(Object? json) {
  if (json is Map<String, dynamic>) {
    return json;
  }

  if (json is Map) {
    return json.map((key, value) => MapEntry(key.toString(), value));
  }

  return const {};
}

List<T> _listFromJson<T>(Object? json, T Function(Object? json) mapper) {
  if (json is List) {
    return json.map(mapper).toList();
  }

  return const [];
}

String _stringValue(Object? value) {
  return value?.toString() ?? '';
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}

double _doubleValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? 0;
  }

  return 0;
}

DateTime? _dateValue(Object? value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}
