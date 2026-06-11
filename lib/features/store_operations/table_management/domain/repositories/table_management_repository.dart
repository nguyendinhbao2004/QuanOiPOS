import '../entities/area.dart';
import '../entities/dining_table.dart';
import '../entities/table_area_group.dart';
import '../entities/table_session.dart';
import '../entities/table_status.dart';

abstract class TableManagementRepository {
  Future<List<Area>> loadAreas(int storeId);

  Future<List<TableAreaGroup>> loadTableGroups({
    required int storeId,
    int? areaId,
  });

  Future<DiningTable> loadTableDetail(int tableId);

  Future<Area> loadAreaDetail(int areaId);

  Future<void> updateTableStatus({
    required int tableId,
    required TableStatus status,
  });

  Future<List<TableSession>> loadTableSessions(int tableId);

  Future<List<TableSession>> loadOpenTableSessions(int tableId);

  Future<TableSession> openTableSession(int tableId);

  Future<TableSession> closeTableSession(int tableSessionId);

  Future<Area> createArea({
    required int storeId,
    required String name,
    required String description,
  });

  Future<DiningTable> createTable({
    required int storeId,
    required int areaId,
    required String name,
    required int capacity,
  });

  Future<DiningTable> updateTable({
    required int tableId,
    required int areaId,
    required String name,
    required int capacity,
  });

  Future<Area> updateArea({
    required int areaId,
    required String name,
    required String description,
  });

  Future<Area> updateAreaDisplayOrder({
    required int areaId,
    required int displayOrder,
  });

  Future<void> deleteArea(int areaId);
}
