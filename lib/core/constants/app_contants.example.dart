import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static String get baseUrl => '$_httpScheme://$_host:4000/v1';
  static String get wsUrl => '$_wsScheme://$_host:4000/v1/ws';
  static const String getstreamApiKey = '';
  static const int wsHeartbeatIntervalSeconds = 10;
  static const int wsMaxReconnectDelaySeconds = 30;

  static String get _httpScheme => 'http';
  static String get _wsScheme => 'ws';

  static String get _host {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) {
      return '192.168.68.91'; // Android emulator → host machine
    }
    return 'localhost'; // iOS simulator, desktop
  }
}

class AppContantsExample {}
