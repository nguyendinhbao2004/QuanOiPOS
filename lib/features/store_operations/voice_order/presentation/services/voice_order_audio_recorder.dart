import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_mp3_plus/record_mp3_plus.dart';

abstract class VoiceOrderAudioRecorder {
  Future<String> start();

  Future<String?> stop();

  Future<void> cancel();
}

class VoiceOrderRecorderPermissionException implements Exception {
  const VoiceOrderRecorderPermissionException();

  @override
  String toString() {
    return 'Ứng dụng cần quyền microphone để ghi âm đơn hàng.';
  }
}

class VoiceOrderRecorderException implements Exception {
  final String message;

  const VoiceOrderRecorderException(this.message);

  @override
  String toString() => message;
}

class RecordMp3VoiceOrderAudioRecorder implements VoiceOrderAudioRecorder {
  String? _currentPath;
  String? _lastPath;

  @override
  Future<String> start() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      throw const VoiceOrderRecorderPermissionException();
    }

    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/voice_order_${DateTime.now().millisecondsSinceEpoch}.mp3';

    String? recordError;
    final didStart = RecordMp3.instance.start(filePath, (error) {
      recordError = error.toString();
    });

    if (!didStart) {
      throw VoiceOrderRecorderException(
        recordError ?? 'Không thể bắt đầu ghi âm.',
      );
    }

    _currentPath = filePath;
    _lastPath = filePath;
    return filePath;
  }

  @override
  Future<String?> stop() async {
    final filePath = _currentPath;
    if (filePath == null) {
      return null;
    }

    final didStop = RecordMp3.instance.stop();
    _currentPath = null;

    if (!didStop) {
      throw const VoiceOrderRecorderException('Không thể dừng ghi âm.');
    }

    return filePath;
  }

  @override
  Future<void> cancel() async {
    final filePath = _currentPath;
    if (filePath != null) {
      RecordMp3.instance.stop();
    }

    final pathToDelete = filePath ?? _lastPath;
    if (pathToDelete != null) {
      final file = File(pathToDelete);
      if (await file.exists()) {
        await file.delete();
      }
    }

    _currentPath = null;
    _lastPath = null;
  }
}
