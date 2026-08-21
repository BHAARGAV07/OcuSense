import 'package:flutter/foundation.dart';

class ApiConfig {
  // Configurable base URL:
  // Android Emulator uses 10.0.2.2 to access host machine localhost.
  // Windows/Web/iOS emulator uses localhost.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

  static const Duration timeoutDuration = Duration(seconds: 15);
}
