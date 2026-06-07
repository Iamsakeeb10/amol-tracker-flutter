import 'package:flutter/foundation.dart';

void exitAppDebug(String message) {
  if (kDebugMode) {
    debugPrint('[ExitApp] $message');
  }
}
