import '../../domain/entities/area.dart';
import '../../domain/entities/table_area_group.dart';
import '../../domain/repositories/table_management_repository.dart';
import '../datasources/table_management_remote_data_source.dart';

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
}
