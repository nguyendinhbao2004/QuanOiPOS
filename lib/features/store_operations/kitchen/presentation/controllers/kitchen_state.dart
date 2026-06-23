import '../../domain/entities/kitchen_order_item.dart';

enum KitchenLoadStatus { initial, loading, ready, forbidden, error }

enum KitchenBoardMode { priority, byTable }

const Duration _vietnamUtcOffset = Duration(hours: 7);

class KitchenAccess {
  final int storeId;
  final String storeName;
  final bool canManageKitchen;

  const KitchenAccess({
    required this.storeId,
    required this.storeName,
    required this.canManageKitchen,
  });
}

class KitchenState {
  final KitchenLoadStatus status;
  final List<KitchenOrderItem> items;
  final KitchenItemFilter filter;
  final KitchenBoardMode mode;
  final Set<int> selectedItemIds;
  final Set<int> processingItemIds;
  final String? errorMessage;
  final bool isRefreshing;
  final bool isBulkProcessing;

  const KitchenState({
    required this.status,
    required this.items,
    required this.filter,
    required this.mode,
    required this.selectedItemIds,
    required this.processingItemIds,
    required this.errorMessage,
    required this.isRefreshing,
    required this.isBulkProcessing,
  });

  const KitchenState.initial()
    : status = KitchenLoadStatus.initial,
      items = const [],
      filter = const KitchenItemFilter(status: KitchenOrderItemStatus.pending),
      mode = KitchenBoardMode.priority,
      selectedItemIds = const {},
      processingItemIds = const {},
      errorMessage = null,
      isRefreshing = false,
      isBulkProcessing = false;

  List<KitchenOrderItem> get visibleItems {
    final list = switch (mode) {
      KitchenBoardMode.priority =>
        [...items]..sort((a, b) {
          final left = a.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final right = b.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return left.compareTo(right);
        }),
      KitchenBoardMode.byTable =>
        [...items]..sort((a, b) {
          final table = a.tableName.compareTo(b.tableName);
          if (table != 0) return table;
          final left = a.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final right = b.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return left.compareTo(right);
        }),
    };

    return list;
  }

  List<KitchenOrderItem> get pendingItems {
    return items
        .where((item) => item.status == KitchenOrderItemStatus.pending)
        .toList();
  }

  KitchenState copyWith({
    KitchenLoadStatus? status,
    List<KitchenOrderItem>? items,
    KitchenItemFilter? filter,
    KitchenBoardMode? mode,
    Set<int>? selectedItemIds,
    Set<int>? processingItemIds,
    String? errorMessage,
    bool? isRefreshing,
    bool? isBulkProcessing,
    bool clearError = false,
  }) {
    return KitchenState(
      status: status ?? this.status,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      mode: mode ?? this.mode,
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      processingItemIds: processingItemIds ?? this.processingItemIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isBulkProcessing: isBulkProcessing ?? this.isBulkProcessing,
    );
  }
}

KitchenItemFilter todayVietnamKitchenFilter({DateTime? nowUtc}) {
  final now = (nowUtc ?? DateTime.now().toUtc()).toUtc();
  final vietnamNow = now.add(_vietnamUtcOffset);
  final vietnamDayStart = DateTime.utc(
    vietnamNow.year,
    vietnamNow.month,
    vietnamNow.day,
  );
  final fromUtc = vietnamDayStart.subtract(_vietnamUtcOffset);
  final toUtc = vietnamDayStart
      .add(const Duration(days: 1))
      .subtract(_vietnamUtcOffset)
      .subtract(const Duration(milliseconds: 1));

  return KitchenItemFilter(
    status: KitchenOrderItemStatus.pending,
    orderedFrom: fromUtc,
    orderedTo: toUtc,
  );
}
