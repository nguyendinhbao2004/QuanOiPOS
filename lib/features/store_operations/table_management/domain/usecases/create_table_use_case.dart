import '../entities/dining_table.dart';
import '../repositories/table_management_repository.dart';

class CreateTableUseCase {
  final TableManagementRepository _repository;

  const CreateTableUseCase(this._repository);

  Future<DiningTable> call({
    required int storeId,
    required int areaId,
    required String name,
    required int capacity,
  }) {
    return _repository.createTable(
      storeId: storeId,
      areaId: areaId,
      name: name,
      capacity: capacity,
    );
  }
}
