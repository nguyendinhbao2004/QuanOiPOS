import '../../domain/entities/inventory_stock.dart';

enum InventoryStockLoadStatus { initial, loading, ready, error }

class InventoryStockListState {
  final InventoryStockLoadStatus status;
  final InventoryStockItemType selectedType;
  final InventoryStockStatus selectedStatus;
  final String searchQuery;
  final List<InventoryStockItem> items;
  final String? errorMessage;

  const InventoryStockListState({
    required this.status,
    required this.selectedType,
    required this.selectedStatus,
    required this.searchQuery,
    required this.items,
    this.errorMessage,
  });

  const InventoryStockListState.initial()
    : status = InventoryStockLoadStatus.initial,
      selectedType = InventoryStockItemType.product,
      selectedStatus = InventoryStockStatus.all,
      searchQuery = '',
      items = const [],
      errorMessage = null;

  List<InventoryStockItem> get visibleItems {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where((item) => item.name.toLowerCase().contains(query))
        .toList();
  }

  double get visibleQuantityTotal =>
      visibleItems.fold(0, (total, item) => total + item.quantity);

  double get visibleValueTotal =>
      visibleItems.fold(0, (total, item) => total + item.inventoryValue);

  InventoryStockListState copyWith({
    InventoryStockLoadStatus? status,
    InventoryStockItemType? selectedType,
    InventoryStockStatus? selectedStatus,
    String? searchQuery,
    List<InventoryStockItem>? items,
    String? errorMessage,
    bool clearError = false,
  }) => InventoryStockListState(
    status: status ?? this.status,
    selectedType: selectedType ?? this.selectedType,
    selectedStatus: selectedStatus ?? this.selectedStatus,
    searchQuery: searchQuery ?? this.searchQuery,
    items: items ?? this.items,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class InventoryMovementState {
  final InventoryStockLoadStatus status;
  final List<InventoryMovement> movements;
  final String? errorMessage;

  const InventoryMovementState({
    required this.status,
    required this.movements,
    this.errorMessage,
  });

  const InventoryMovementState.initial()
    : status = InventoryStockLoadStatus.initial,
      movements = const [],
      errorMessage = null;

  InventoryMovementState copyWith({
    InventoryStockLoadStatus? status,
    List<InventoryMovement>? movements,
    String? errorMessage,
    bool clearError = false,
  }) => InventoryMovementState(
    status: status ?? this.status,
    movements: movements ?? this.movements,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}
