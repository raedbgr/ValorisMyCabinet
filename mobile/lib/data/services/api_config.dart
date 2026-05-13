import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  static String get apiUrl => '$baseUrl/api';

  static const Duration timeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 90);

  static const String defaultClientId = 'usr_001';
}
