import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../features/auth/data/models/session_snapshot_model.dart';
import 'session_snapshot_storage.dart';

class SessionSnapshotStorageImpl implements SessionSnapshotStorage {
  final SharedPreferences _prefs;

  SessionSnapshotStorageImpl(this._prefs);

  static const _snapshotKey = 'session_snapshot';

  @override
  Future<SessionSnapshot?> getSnapshot() async {
    try {
      final jsonStr = _prefs.getString(_snapshotKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return SessionSnapshot.fromJson(json);
    } catch (e) {
      // Corrupted data; clear and return null
      await clearSnapshot();
      return null;
    }
  }

  @override
  Future<void> saveSnapshot(SessionSnapshot snapshot) async {
    final json = snapshot.toJson();
    final jsonStr = jsonEncode(json);
    await _prefs.setString(_snapshotKey, jsonStr);
  }

  @override
  Future<void> clearSnapshot() async {
    await _prefs.remove(_snapshotKey);
  }
}
