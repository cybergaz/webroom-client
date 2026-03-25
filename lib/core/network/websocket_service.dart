import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';
import '../constants/storage_keys.dart';
import '../storage/secure_storage.dart';
import '../../domain/enums/ws_connection_state.dart';

class WebSocketService {
  final SecureStorageService _storage;
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isConnecting = false;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController =
      StreamController<WsConnectionState>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;
  Stream<WsConnectionState> get connectionState =>
      _connectionStateController.stream;
  WsConnectionState get currentState => _currentState;

  WsConnectionState _currentState = WsConnectionState.disconnected;

  WebSocketService(this._storage);

  Future<void> connect() async {
    if (_isConnecting || _currentState == WsConnectionState.connected) return;

    final token = await _storage.read(StorageKeys.accessToken);
    if (token == null) return;

    _isConnecting = true;
    _updateState(WsConnectionState.reconnecting);

    try {
      final uri = Uri.parse('${AppConstants.wsUrl}?token=$token');
      // Cancel old subscription before replacing the channel.
      _channelSubscription?.cancel();
      _channelSubscription = null;
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _isConnecting = false;
      _reconnectAttempts = 0;
      _updateState(WsConnectionState.connected);
      print("────────────────────────────────────────────────────────────────");
      print('WebSocket connected to ${uri.toString()}');
      print("────────────────────────────────────────────────────────────────");
      _startHeartbeat();

      _channelSubscription = _channel!.stream.listen(
        (data) {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          // Intercept auth errors before forwarding to listeners
          if (json['type'] == 'socket:error') {
            final code = json['error_code'] as String?;
            if (code == 'AUTH_REQUIRED' || code == 'AUTH_INVALID') {
              _refreshTokenAndReconnect();
              return;
            }
          }
          _eventController.add(json);
        },
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
      );
    } catch (_) {
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void send(String event, [Map<String, dynamic>? payload]) {
    if (_currentState != WsConnectionState.connected) return;
    _channel?.sink.add(jsonEncode({'event': event, 'payload': payload ?? {}}));
  }

  /// Sends a speaking event in the fire-and-forget format required by the server.
  /// [type] is either 'speaking.start' or 'speaking.end'.
  void sendSpeakingEvent(String type) {
    if (_currentState != WsConnectionState.connected) return;
    _channel?.sink.add(jsonEncode({'type': type}));
  }

  Future<void> _refreshTokenAndReconnect() async {
    print('WS auth error — refreshing token');
    _heartbeatTimer?.cancel();
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _updateState(WsConnectionState.disconnected);

    try {
      final refreshToken = await _storage.read(StorageKeys.refreshToken);
      if (refreshToken == null) {
        await _storage.deleteAll();
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        headers: {'Content-Type': 'application/json'},
      ));
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      await _storage.write(
        StorageKeys.accessToken,
        response.data['accessToken'] as String,
      );
      await _storage.write(
        StorageKeys.refreshToken,
        response.data['refreshToken'] as String,
      );

      _isConnecting = false;
      _currentState = WsConnectionState.disconnected;
      _reconnectAttempts = 0;
      await connect();
    } catch (e) {
      print('WS token refresh failed: $e');
      // Do NOT clear storage here — HTTP auth interceptor owns that decision
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: AppConstants.wsHeartbeatIntervalSeconds),
      (_) => send('ws.ping'),
    );
  }

  void _onDisconnected() {
    print("────────────────────────────────────────────────────────────────");
    print('WebSocket disconnected');
    print("────────────────────────────────────────────────────────────────");
    _heartbeatTimer?.cancel();
    _updateState(WsConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    print("────────────────────────────────────────────────────────────────");
    print('Scheduling WebSocket reconnect attempt #$_reconnectAttempts');
    print("────────────────────────────────────────────────────────────────");
    _reconnectTimer?.cancel();
    final delay = min(
      pow(2, _reconnectAttempts).toInt(),
      AppConstants.wsMaxReconnectDelaySeconds,
    );
    _reconnectAttempts++;
    _updateState(WsConnectionState.reconnecting);
    _reconnectTimer = Timer(Duration(seconds: delay), connect);
  }

  void _updateState(WsConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _isConnecting = false;
    _channelSubscription?.cancel();
    _channelSubscription = null;
    await _channel?.sink.close();
    _updateState(WsConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionStateController.close();
  }
}

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  final storage = ref.read(secureStorageProvider);
  final service = WebSocketService(storage);
  ref.onDispose(service.dispose);
  return service;
});
