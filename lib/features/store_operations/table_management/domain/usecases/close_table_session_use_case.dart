import '../entities/table_session.dart';
import '../repositories/table_management_repository.dart';

class CloseTableSessionUseCase {
  final TableManagementRepository _repository;

  const CloseTableSessionUseCase(this._repository);

  Future<TableSession> call(int tableSessionId) {
    return _repository.closeTableSession(tableSessionId);
  }
}
