import '../../features/auth/data/models/session_snapshot_model.dart';

abstract class SessionSnapshotStorage {
  Future<SessionSnapshot?> getSnapshot();

  Future<void> saveSnapshot(SessionSnapshot snapshot);

  Future<void> clearSnapshot();
}
