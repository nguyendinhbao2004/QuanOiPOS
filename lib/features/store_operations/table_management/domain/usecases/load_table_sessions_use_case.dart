import '../entities/table_session.dart';
import '../repositories/table_management_repository.dart';

class LoadTableSessionsUseCase {
  final TableManagementRepository _repository;

  const LoadTableSessionsUseCase(this._repository);

  Future<List<TableSession>> call(int tableId) {
    return _repository.loadTableSessions(tableId);
  }
}
