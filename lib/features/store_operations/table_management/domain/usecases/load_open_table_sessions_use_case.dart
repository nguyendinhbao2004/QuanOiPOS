import '../entities/table_session.dart';
import '../repositories/table_management_repository.dart';

class LoadOpenTableSessionsUseCase {
  final TableManagementRepository _repository;

  const LoadOpenTableSessionsUseCase(this._repository);

  Future<List<TableSession>> call(int tableId) {
    return _repository.loadOpenTableSessions(tableId);
  }
}
