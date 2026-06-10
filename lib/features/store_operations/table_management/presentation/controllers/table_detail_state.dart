import '../../domain/entities/area.dart';
import '../../domain/entities/dining_table.dart';
import '../../domain/entities/table_session.dart';

enum TableDetailStatus { initial, loading, ready, forbidden, error }

class TableDetailAccess {
  final int storeId;
  final int tableId;
  final bool canViewTable;
  final bool canUpdateTable;
  final bool canOpenSession;

  const TableDetailAccess({
    required this.storeId,
    required this.tableId,
    required this.canViewTable,
    required this.canUpdateTable,
    required this.canOpenSession,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TableDetailAccess &&
            runtimeType == other.runtimeType &&
            storeId == other.storeId &&
            tableId == other.tableId &&
            canViewTable == other.canViewTable &&
            canUpdateTable == other.canUpdateTable &&
            canOpenSession == other.canOpenSession;
  }

  @override
  int get hashCode => Object.hash(
    storeId,
    tableId,
    canViewTable,
    canUpdateTable,
    canOpenSession,
  );
}

class TableDetailState {
  final TableDetailStatus status;
  final DiningTable? table;
  final Area? area;
  final List<TableSession> sessions;
  final bool isMutating;
  final bool hasChanged;
  final String? errorMessage;

  const TableDetailState({
    required this.status,
    this.table,
    this.area,
    this.sessions = const [],
    this.isMutating = false,
    this.hasChanged = false,
    this.errorMessage,
  });

  const TableDetailState.initial()
    : status = TableDetailStatus.initial,
      table = null,
      area = null,
      sessions = const [],
      isMutating = false,
      hasChanged = false,
      errorMessage = null;

  bool get isLoading =>
      status == TableDetailStatus.initial ||
      status == TableDetailStatus.loading;

  TableSession? get currentSession {
    for (final session in sessions) {
      if (session.status == TableSessionStatus.open) {
        return session;
      }
    }

    return null;
  }

  List<TableSession> get historySessions {
    return sessions
        .where(
          (session) =>
              session.status == TableSessionStatus.closed ||
              session.status == TableSessionStatus.cancelled,
        )
        .toList();
  }

  String get areaName {
    final tableAreaId = table?.areaId;
    if (area != null) {
      return area!.name;
    }

    return tableAreaId == null ? 'Khu vực' : 'Khu vực #$tableAreaId';
  }

  TableDetailState copyWith({
    TableDetailStatus? status,
    DiningTable? table,
    Area? area,
    bool clearArea = false,
    List<TableSession>? sessions,
    bool? isMutating,
    bool? hasChanged,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TableDetailState(
      status: status ?? this.status,
      table: table ?? this.table,
      area: clearArea ? null : (area ?? this.area),
      sessions: sessions ?? this.sessions,
      isMutating: isMutating ?? this.isMutating,
      hasChanged: hasChanged ?? this.hasChanged,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
