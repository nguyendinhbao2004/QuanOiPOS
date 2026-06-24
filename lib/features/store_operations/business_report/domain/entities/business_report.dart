class BusinessReport {
  final int id;
  final int storeId;
  final int type;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String content;
  final BusinessReportMetrics metrics;
  final DateTime? createdAt;

  const BusinessReport({
    required this.id,
    required this.storeId,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.content,
    required this.metrics,
    required this.createdAt,
  });
}

class BusinessReportMetrics {
  final RevenueSummary revenueSummary;
  final ProfitSummary profitSummary;
  final PurchaseSummary purchaseSummary;
  final List<TopProductMetric> topProducts;
  final List<HourlyOrderMetric> hourlyOrders;
  final List<HourlyProductSaleMetric> hourlyProductSales;
  final InventorySummary inventorySummary;
  final List<InventoryRecommendation> inventoryRecommendations;

  const BusinessReportMetrics({
    required this.revenueSummary,
    required this.profitSummary,
    required this.purchaseSummary,
    required this.topProducts,
    required this.hourlyOrders,
    required this.hourlyProductSales,
    required this.inventorySummary,
    required this.inventoryRecommendations,
  });

  const BusinessReportMetrics.empty()
    : revenueSummary = const RevenueSummary.empty(),
      profitSummary = const ProfitSummary.empty(),
      purchaseSummary = const PurchaseSummary.empty(),
      topProducts = const [],
      hourlyOrders = const [],
      hourlyProductSales = const [],
      inventorySummary = const InventorySummary.empty(),
      inventoryRecommendations = const [];
}

class RevenueSummary {
  final double totalRevenue;
  final double paidRevenue;
  final int completedOrderCount;
  final int cancelledOrderCount;
  final double averageOrderValue;

  const RevenueSummary({
    required this.totalRevenue,
    required this.paidRevenue,
    required this.completedOrderCount,
    required this.cancelledOrderCount,
    required this.averageOrderValue,
  });

  const RevenueSummary.empty()
    : totalRevenue = 0,
      paidRevenue = 0,
      completedOrderCount = 0,
      cancelledOrderCount = 0,
      averageOrderValue = 0;
}

class ProfitSummary {
  final double totalCost;
  final double grossProfit;
  final double grossProfitMargin;

  const ProfitSummary({
    required this.totalCost,
    required this.grossProfit,
    required this.grossProfitMargin,
  });

  const ProfitSummary.empty()
    : totalCost = 0,
      grossProfit = 0,
      grossProfitMargin = 0;
}

class PurchaseSummary {
  final double totalPurchaseCost;
  final int purchaseMovementCount;

  const PurchaseSummary({
    required this.totalPurchaseCost,
    required this.purchaseMovementCount,
  });

  const PurchaseSummary.empty()
    : totalPurchaseCost = 0,
      purchaseMovementCount = 0;
}

class TopProductMetric {
  final int productId;
  final String productName;
  final double quantitySold;
  final double revenue;
  final double cost;
  final double grossProfit;
  final double grossProfitMargin;

  const TopProductMetric({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
    required this.cost,
    required this.grossProfit,
    required this.grossProfitMargin,
  });
}

class HourlyOrderMetric {
  final int hour;
  final int orderCount;
  final double revenue;

  const HourlyOrderMetric({
    required this.hour,
    required this.orderCount,
    required this.revenue,
  });
}

class HourlyProductSaleMetric {
  final int hour;
  final int productId;
  final String productName;
  final double quantitySold;
  final double revenue;
  final double grossProfit;

  const HourlyProductSaleMetric({
    required this.hour,
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
    required this.grossProfit,
  });
}

class InventorySummary {
  final int lowStockCount;
  final int outOfStockCount;
  final int missingRecipeProductCount;
  final List<InventoryAttentionItem> lowStockItems;
  final List<InventoryAttentionItem> outOfStockItems;

  const InventorySummary({
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.missingRecipeProductCount,
    required this.lowStockItems,
    required this.outOfStockItems,
  });

  const InventorySummary.empty()
    : lowStockCount = 0,
      outOfStockCount = 0,
      missingRecipeProductCount = 0,
      lowStockItems = const [],
      outOfStockItems = const [];
}

class InventoryAttentionItem {
  final String itemType;
  final int itemId;
  final String itemName;
  final double quantity;
  final String unit;
  final double minimumStock;

  const InventoryAttentionItem({
    required this.itemType,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.minimumStock,
  });
}

class InventoryRecommendation {
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

  const InventoryRecommendation({
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

  bool get isRestock => recommendationType.toLowerCase() == 'restock';
}
