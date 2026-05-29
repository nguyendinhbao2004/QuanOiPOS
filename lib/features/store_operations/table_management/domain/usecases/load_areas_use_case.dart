import '../entities/area.dart';
import '../repositories/table_management_repository.dart';

class LoadAreasUseCase {
  final TableManagementRepository _repository;

  const LoadAreasUseCase(this._repository);

  Future<List<Area>> call(int storeId) {
    return _repository.loadAreas(storeId);
  }
}
