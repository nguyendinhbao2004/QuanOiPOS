import '../entities/area.dart';
import '../repositories/table_management_repository.dart';

class LoadAreaDetailUseCase {
  final TableManagementRepository _repository;

  const LoadAreaDetailUseCase(this._repository);

  Future<Area> call(int areaId) {
    return _repository.loadAreaDetail(areaId);
  }
}
