import '../entities/area.dart';
import '../entities/table_area_group.dart';

abstract class TableManagementRepository {
  Future<List<Area>> loadAreas(int storeId);

  Future<List<TableAreaGroup>> loadTableGroups({
    required int storeId,
    int? areaId,
  });
}
