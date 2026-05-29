import '../entities/table_area_group.dart';
import '../repositories/table_management_repository.dart';

class LoadTableGroupsUseCase {
  final TableManagementRepository _repository;

  const LoadTableGroupsUseCase(this._repository);

  Future<List<TableAreaGroup>> call({required int storeId, int? areaId}) {
    return _repository.loadTableGroups(storeId: storeId, areaId: areaId);
  }
}
