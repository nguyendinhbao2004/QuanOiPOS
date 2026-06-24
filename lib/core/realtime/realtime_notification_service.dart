import 'dart:async';

import 'realtime_notification_message.dart';

abstract class RealtimeNotificationService {
  Stream<RealtimeNotificationMessage> get messages;

  Future<void> start();

  Future<void> stop();

  Future<void> restart();

  Future<void> joinStore(int storeId);

  Future<void> leaveStore(int storeId);
}

class NoopRealtimeNotificationService implements RealtimeNotificationService {
  const NoopRealtimeNotificationService();

  @override
  Stream<RealtimeNotificationMessage> get messages => const Stream.empty();

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> restart() async {}

  @override
  Future<void> joinStore(int storeId) async {}

  @override
  Future<void> leaveStore(int storeId) async {}
}
