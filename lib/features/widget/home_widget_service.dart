import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/constants/amal_fields.dart';
import '../../core/constants/default_amal_fields.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/utils/score_calculator.dart';
import 'widget_score_label.dart';

/// Service to push amal data to the Android home screen widget.
///
/// This should be called after:
/// - Every amal toggle/numeric change
/// - After amal submission
/// - On app resume
/// - When Islamic date changes (after Maghrib)
class HomeWidgetService {
  HomeWidgetService._();

  static const String _appGroupId = 'com.sakib.amol_tracker_app';
  static const String _iOSWidgetName =
      'AmolWidget'; // TODO: iOS WidgetKit support
  static const String _androidWidgetName = 'AmolWidgetProvider';

  /// Update the home screen widget with current amal state.
  static Future<void> updateWidget({
    required String hijriDateDisplay,
    required int score,
    required int maxScore,
    required int completedCount,
    required int totalCount,
    required bool isSubmitted,
    required Map<String, dynamic> toggles,
    required List<AmalField> fields,
    int currentStreak = 0,
  }) async {
    try {
      final activeFields = getActiveFields(fields);

      await HomeWidget.saveWidgetData('hijriDateDisplay', hijriDateDisplay);
      await HomeWidget.saveWidgetData('score', score);
      await HomeWidget.saveWidgetData('maxScore', maxScore);
      await HomeWidget.saveWidgetData('completedCount', completedCount);
      await HomeWidget.saveWidgetData('totalCount', totalCount);
      await HomeWidget.saveWidgetData('isSubmitted', isSubmitted);
      await HomeWidget.saveWidgetData('currentStreak', currentStreak);
      await HomeWidget.saveWidgetData('scoreLabel', widgetScoreLabel(score));
      await HomeWidget.saveWidgetData(
        'amalFieldIds',
        activeFields.map((f) => f.id).join(','),
      );

      final locale = _widgetLocale();
      final fieldsMeta = activeFields
          .map(
            (f) => <String, dynamic>{
              'id': f.id,
              'label': f.getLabel(locale),
              'type': f.type == AmalType.numeric ? 1 : 0,
              'max': f.maxValue,
            },
          )
          .toList();
      await HomeWidget.saveWidgetData('amalFieldsMeta', jsonEncode(fieldsMeta));

      for (final field in activeFields) {
        final value = toggles[field.id];
        if (field.type == AmalType.numeric) {
          final intVal = getNumericValue(value, field.maxValue);
          await HomeWidget.saveWidgetData('amal_${field.id}', intVal.toString());
        } else {
          await HomeWidget.saveWidgetData(
            'amal_${field.id}',
            (value == true).toString(),
          );
        }
      }

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
        qualifiedAndroidName:
            'com.shakib.amol.amol_tracker_app.$_androidWidgetName',
      );
    } catch (e) {
      debugPrint('HomeWidgetService: update failed — $e');
    }
  }

  static Future<Uri?> getWidgetLaunchUri() async {
    return HomeWidget.initiallyLaunchedFromHomeWidget();
  }

  static void registerInteractivityCallback(Function(Uri?) onWidgetTap) {
    HomeWidget.setAppGroupId(_appGroupId);
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) onWidgetTap(uri);
    });
  }

  static int calculateCompletedCount(
    Map<String, dynamic> toggles,
    List<AmalField> fields,
  ) {
    return toggles.entries.where((entry) {
      final field = fields.where((f) => f.id == entry.key).firstOrNull;
      if (field == null) return false;

      if (field.type == AmalType.boolean) {
        return entry.value == true;
      } else {
        final val = entry.value is int ? entry.value as int : 0;
        return val > 0;
      }
    }).length;
  }

  static List<AmalField> getActiveFields(List<AmalField> fields) {
    return resolveAmalFields(fields);
  }

  static String _widgetLocale() {
    final code = LocalStorageService.getPref<String>('app_locale', 'bn');
    return code == 'en' ? 'en' : 'bn';
  }
}
