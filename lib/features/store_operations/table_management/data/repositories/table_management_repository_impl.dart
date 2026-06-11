import '../../domain/entities/area.dart';
import '../../domain/entities/dining_table.dart';
import '../../domain/entities/table_area_group.dart';
import '../../domain/entities/table_session.dart';
import '../../domain/entities/table_status.dart';
import '../../domain/repositories/table_management_repository.dart';
import '../datasources/table_management_remote_data_source.dart';
import '../models/area_request_models.dart';
import '../models/table_session_model.dart';
import '../models/table_request_models.dart';

class TableManagementRepositoryImpl implements TableManagementRepository {
  final TableManagementRemoteDataSource _remoteDataSource;

  const TableManagementRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Area>> loadAreas(int storeId) async {
    final areas = await _remoteDataSource.getAreasByStore(storeId);
    final entities = areas
        .where((area) => !area.isDeleted)
        .map((area) => area.toEntity())
        .toList();

    entities.sort((left, right) {
      final orderCompare = left.displayOrder.compareTo(right.displayOrder);
      if (orderCompare != 0) {
        return orderCompare;
      }

      return left.name.compareTo(right.name);
    });

    return entities;
  }

  @override
  Future<List<TableAreaGroup>> loadTableGroups({
    required int storeId,
    int? areaId,
  }) async {
    final groups = await _remoteDataSource.getTableGroupsByStore(
      storeId: storeId,
      areaId: areaId,
    );

    final entities = groups.where((group) => !group.area.isDeleted).map((
      group,
    ) {
      final entity = group.toEntity();
      final activeTables = entity.tables
          .where((table) => !table.isDeleted)
          .toList();
      return TableAreaGroup(area: entity.area, tables: activeTables);
    }).toList();

    entities.sort((left, right) {
      final orderCompare = left.area.displayOrder.compareTo(
        right.area.displayOrder,
      );
      if (orderCompare != 0) {
        return orderCompare;
      }

      return left.area.name.compareTo(right.area.name);
    });

    return entities;
  }

  @override
  Future<DiningTable> loadTableDetail(int tableId) async {
    final table = await _remoteDataSource.getTableById(tableId);
    return table.toEntity();
  }

  @override
  Future<Area> loadAreaDetail(int areaId) async {
    final area = await _remoteDataSource.getAreaById(areaId);
    return area.toEntity();
  }

  @override
  Future<Area> createArea({
    required int storeId,
    required String name,
    required String description,
  }) async {
    final area = await _remoteDataSource.createArea(
      CreateAreaRequestModel(
        storeId: storeId,
        name: name,
        description: description,
      ),
    );

    return area.toEntity();
  }

  @override
  Future<DiningTable> createTable({
    required int storeId,
    required int areaId,
    required String name,
    required int capacity,
  }) async {
    final table = await _remoteDataSource.createTable(
      CreateTableRequestModel(
        storeId: storeId,
        areaId: areaId,
        name: name,
        capacity: capacity,
      ),
    );

    return table.toEntity();
  }

  @override
  Future<DiningTable> updateTable({
    required int tableId,
    required int areaId,
    required String name,
    required int capacity,
  }) async {
    final table = await _remoteDataSource.updateTable(
      tableId: tableId,
      request: UpdateTableRequestModel(
        areaId: areaId,
        name: name,
        capacity: capacity,
      ),
    );

    return table.toEntity();
  }

  @override
  Future<void> updateTableStatus({
    required int tableId,
    required TableStatus status,
  }) {
    return _remoteDataSource.updateTableStatus(
      tableId: tableId,
      request: UpdateTableStatusRequestModel(status: status.apiValue),
    );
  }

  @override
  Future<List<TableSession>> loadTableSessions(int tableId) async {
    final sessions = await _remoteDataSource.getTableSessionsByTable(tableId);
    return _mapAndSortSessions(sessions);
  }

  @override
  Future<List<TableSession>> loadOpenTableSessions(int tableId) async {
    final sessions = await _remoteDataSource.getOpenTableSessionsByTable(
      tableId,
    );
    return _mapAndSortSessions(
      sessions,
    ).where((session) => session.status == TableSessionStatus.open).toList();
  }

  List<TableSession> _mapAndSortSessions(Iterable<TableSessionModel> sessions) {
    final entities = sessions
        .where((session) => !session.isDeleted)
        .map((session) => session.toEntity())
        .toList();

    entities.sort((left, right) {
      final leftTime = left.openTime ?? left.createdAt ?? DateTime(0);
      final rightTime = right.openTime ?? right.createdAt ?? DateTime(0);
      return rightTime.compareTo(leftTime);
    });

    return entities;
  }

  @override
  Future<TableSession> openTableSession(int tableId) async {
    final session = await _remoteDataSource.openTableSession(
      OpenTableSessionRequestModel(tableId: tableId),
    );
    return session.toEntity();
  }

  @override
  Future<void> closeTableSession(int tableSessionId) {
    return _remoteDataSource.closeTableSession(tableSessionId);
  }

  @override
  Future<Area> updateArea({
    required int areaId,
    required String name,
    required String description,
  }) async {
    final area = await _remoteDataSource.updateArea(
      areaId: areaId,
      request: UpdateAreaRequestModel(name: name, description: description),
    );

    return area.toEntity();
  }

  @override
  Future<Area> updateAreaDisplayOrder({
    required int areaId,
    required int displayOrder,
  }) async {
    final area = await _remoteDataSource.updateAreaDisplayOrder(
      areaId: areaId,
      request: UpdateAreaDisplayOrderRequestModel(displayOrder: displayOrder),
    );

    return area.toEntity();
  }

  @override
  Future<void> deleteArea(int areaId) {
    return _remoteDataSource.deleteArea(areaId);
  }
}
