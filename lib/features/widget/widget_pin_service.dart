import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class WidgetPinService {
  WidgetPinService._();

  static const String _androidWidgetName = 'AmolWidgetProvider';
  static const String _qualifiedAndroidWidgetName =
      'com.shakib.amol.amol_tracker_app.$_androidWidgetName';

  static Future<bool> isPinSupported() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPin() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      await HomeWidget.requestPinWidget(
        androidName: _androidWidgetName,
        qualifiedAndroidName: _qualifiedAndroidWidgetName,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
