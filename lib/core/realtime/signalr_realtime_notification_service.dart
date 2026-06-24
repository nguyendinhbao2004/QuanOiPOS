import 'dart:async';

import 'package:logger/logger.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../env/env.dart';
import '../storage/token_storage.dart';
import 'realtime_notification_message.dart';
import 'realtime_notification_service.dart';

class SignalRRealtimeNotificationService
    implements RealtimeNotificationService {
  final TokenStorage _tokenStorage;
  final Logger _logger;
  final String _hubUrl;

  final StreamController<RealtimeNotificationMessage> _messagesController =
      StreamController<RealtimeNotificationMessage>.broadcast();

  HubConnection? _connection;
  Future<void>? _startFuture;
  bool _isStarted = false;
  final Set<int> _joinedStoreIds = <int>{};

  SignalRRealtimeNotificationService({
    required TokenStorage tokenStorage,
    required Logger logger,
    String? hubUrl,
  }) : _tokenStorage = tokenStorage,
       _logger = logger,
       _hubUrl = hubUrl ?? Env.notificationsHubUrl;

  @override
  Stream<RealtimeNotificationMessage> get messages =>
      _messagesController.stream;

  @override
  Future<void> start() async {
    if (_isStarted || _hubUrl.isEmpty) {
      return;
    }
    final activeStart = _startFuture;
    if (activeStart != null) {
      await activeStart;
      return;
    }

    final startFuture = _startConnection();
    _startFuture = startFuture;
    await startFuture;
  }

  Future<void> _startConnection() async {
    try {
      final connection = _connection ?? _buildConnection();
      _connection = connection;
      await connection.start();
      _isStarted = true;
    } catch (error) {
      _logger.w('SignalR notification hub connection failed: $error');
    } finally {
      _startFuture = null;
    }
  }

  @override
  Future<void> stop() async {
    final connection = _connection;
    _isStarted = false;
    _startFuture = null;

    if (connection == null) {
      return;
    }

    try {
      await connection.stop();
    } catch (error) {
      _logger.w('SignalR notification hub stop failed: $error');
    }
  }

  @override
  Future<void> restart() async {
    await stop();
    _connection = null;
    await start();
  }

  @override
  Future<void> joinStore(int storeId) async {
    if (storeId <= 0) {
      return;
    }

    _joinedStoreIds.add(storeId);
    await start();
    await _invokeStoreMembership('JoinStore', storeId);
  }

  @override
  Future<void> leaveStore(int storeId) async {
    if (storeId <= 0) {
      return;
    }

    _joinedStoreIds.remove(storeId);
    await _invokeStoreMembership('LeaveStore', storeId);
  }

  Future<void> dispose() async {
    await stop();
    await _messagesController.close();
  }

  HubConnection _buildConnection() {
    final connection = HubConnectionBuilder()
        .withUrl(
          _hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async =>
                await _tokenStorage.getAccessToken() ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    connection.on('ReceiveNotification', _handleReceiveNotification);
    connection.onreconnecting(({error}) {
      _isStarted = false;
    });
    connection.onreconnected(({connectionId}) {
      _isStarted = true;
      unawaited(_rejoinStores());
    });
    connection.onclose(({error}) {
      _isStarted = false;
      if (error != null) {
        _logger.w('SignalR notification hub closed: $error');
      }
    });

    return connection;
  }

  void _handleReceiveNotification(List<Object?>? arguments) {
    final raw = arguments == null || arguments.isEmpty ? null : arguments.first;

    try {
      final message = RealtimeNotificationMessage.fromJson(raw);
      _messagesController.add(message);
    } catch (error) {
      _logger.w('Invalid realtime notification payload: $error');
    }
  }

  Future<void> _rejoinStores() async {
    for (final storeId in _joinedStoreIds) {
      await _invokeStoreMembership('JoinStore', storeId);
    }
  }

  Future<void> _invokeStoreMembership(String methodName, int storeId) async {
    final connection = _connection;
    if (!_isStarted || connection == null) {
      return;
    }

    try {
      await connection.invoke(methodName, args: <Object>[storeId]);
    } catch (error) {
      _logger.w('SignalR $methodName($storeId) failed: $error');
    }
  }
}
