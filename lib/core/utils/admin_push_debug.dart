import 'package:flutter/foundation.dart';

/// Debug-only logging for admin broadcast push gateway calls.
void logAdminPushDebug(String message) {
  if (kDebugMode) {
    debugPrint('[AdminPush] $message');
  }
}
