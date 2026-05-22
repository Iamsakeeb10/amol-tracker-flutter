import 'package:flutter/foundation.dart';

/// Debug-only logging for amal edit eligibility (Hijri window, logs, etc.).
void logAmalEditDebug(String message) {
  if (kDebugMode) {
    debugPrint('[AmalEdit] $message');
  }
}
