import '../entities/table_status.dart';
import '../repositories/table_management_repository.dart';

class UpdateTableStatusUseCase {
  final TableManagementRepository _repository;

  const UpdateTableStatusUseCase(this._repository);

  Future<void> call({required int tableId, required TableStatus status}) {
    return _repository.updateTableStatus(tableId: tableId, status: status);
  }
}
