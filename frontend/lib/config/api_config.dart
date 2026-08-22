import 'package:flutter/foundation.dart';

class ApiConfig {
  // Configurable base URL:
  // Android Emulator uses 10.0.2.2 to access host machine localhost.
  // Physical Android APK builds use the backend machine's LAN IP.
  // Windows/Web/iOS emulator uses localhost.
  static const String lanBackendUrl = 'http://10.163.243.213:8000';
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return lanBackendUrl;
    } else {
      return 'http://localhost:8000';
    }
  }

  static const Duration timeoutDuration = Duration(seconds: 15);
}
