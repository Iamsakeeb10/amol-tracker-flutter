import 'package:flutter/foundation.dart';

/// Debug-only logging for dua Firestore writes and FCM push gateway calls.
void logDuaPushDebug(String message) {
  if (kDebugMode) {
    debugPrint('[DuaPush] $message');
  }
}
