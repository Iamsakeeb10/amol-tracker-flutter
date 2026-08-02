import 'package:hive_flutter/hive_flutter.dart';

import 'islamic_date_service.dart';
import 'local_storage_service.dart';

/// Performs lightweight, non-blocking cleanup of local Hive data that is no
/// longer needed. Runs on every app resume (via `_onAppResumed`) but uses a
/// daily guard so the actual work only executes once per day.
class BackgroundCleanupService {
  BackgroundCleanupService._();

  static const String _lastCleanupKey = 'background_cleanup_last_run';
  static const int _retainDays = 14;

  /// Call from `_onAppResumed`. No-op if cleanup already ran today.
  static Future<void> runIfDue() async {
    try {
      final prefs = Hive.box<dynamic>(LocalStorageService.prefsBox);
      final lastRun = prefs.get(_lastCleanupKey) as String?;
      final today = IslamicDateService.getCurrentIslamicDateStringSafe();

      if (lastRun == today) return;

      await _performCleanup();
      await prefs.put(_lastCleanupKey, today);
    } catch (_) {
      // Never block the app lifecycle on cleanup failures.
    }
  }

  static Future<void> _performCleanup() async {
    final today = IslamicDateService.getCurrentIslamicDateStringSafe();
    final cutoff = IslamicDateService.shiftStorageByDays(today, -_retainDays);

    await _cleanAmalLogs(cutoff);
    await _cleanDhikrSessions(cutoff);
  }

  /// Remove cached amal logs older than [cutoff] Hijri date.
  static Future<void> _cleanAmalLogs(String cutoff) async {
    try {
      final box = Hive.box<dynamic>(LocalStorageService.amalLogsBox);
      final staleKeys = <dynamic>[];

      for (final key in box.keys) {
        final keyStr = key.toString();
        // Keys: log_{uid}_{hijriDate}, draft_{uid}_{hijriDate}, selections_{uid}_{hijriDate}
        if (!keyStr.startsWith('log_') &&
            !keyStr.startsWith('draft_') &&
            !keyStr.startsWith('selections_')) {
          continue;
        }
        // Extract the hijri date (last 3 segments: YYYY-MM-DD).
        final parts = keyStr.split('_');
        if (parts.length < 3) continue;
        final hijriDate = parts.sublist(parts.length - 3).join('_');
        if (hijriDate.compareTo(cutoff) < 0) {
          staleKeys.add(key);
        }
      }

      if (staleKeys.isNotEmpty) {
        await box.deleteAll(staleKeys);
      }
    } catch (_) {}
  }

  /// Remove cached dhikr sessions older than [cutoff] Hijri date.
  static Future<void> _cleanDhikrSessions(String cutoff) async {
    try {
      final box = Hive.box<dynamic>(LocalStorageService.amalLogsBox);
      final staleKeys = <dynamic>[];

      for (final key in box.keys) {
        final keyStr = key.toString();
        if (!keyStr.startsWith('dhikr_')) continue;
        final hijriDate = keyStr.substring('dhikr_'.length);
        if (hijriDate.compareTo(cutoff) < 0) {
          staleKeys.add(key);
        }
      }

      if (staleKeys.isNotEmpty) {
        await box.deleteAll(staleKeys);
      }
    } catch (_) {}
  }
}
