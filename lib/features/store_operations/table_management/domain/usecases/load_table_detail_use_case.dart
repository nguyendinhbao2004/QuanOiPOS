import '../entities/dining_table.dart';
import '../repositories/table_management_repository.dart';

class LoadTableDetailUseCase {
  final TableManagementRepository _repository;

  const LoadTableDetailUseCase(this._repository);

  Future<DiningTable> call(int tableId) {
    return _repository.loadTableDetail(tableId);
  }
}
