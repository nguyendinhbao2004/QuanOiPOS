import '../entities/table_session.dart';
import '../repositories/table_management_repository.dart';

class OpenTableSessionUseCase {
  final TableManagementRepository _repository;

  const OpenTableSessionUseCase(this._repository);

  Future<TableSession> call(int tableId) {
    return _repository.openTableSession(tableId);
  }
}
