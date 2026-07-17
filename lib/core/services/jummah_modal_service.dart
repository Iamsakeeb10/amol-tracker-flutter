
import 'islamic_date_service.dart';
import 'local_storage_service.dart';

class JummahModalService {
  JummahModalService._();

  static const String _lastShownKey = 'jummah_modal_last_shown';

  static bool isTodayFriday() {
    final bdNow = IslamicDateService.nowInBD();
    return bdNow.weekday == DateTime.friday;
  }

  static bool _hasShownThisFriday() {
    final lastShown = LocalStorageService.getPref<String>(_lastShownKey, '');
    if (lastShown.isEmpty) return false;

    final todayGregorian = _todayGregorianString();
    return lastShown == todayGregorian;
  }

  static bool shouldShow() {
    return isTodayFriday() && !_hasShownThisFriday();
  }

  static Future<void> markShown() async {
    final todayGregorian = _todayGregorianString();
    await LocalStorageService.setPref(_lastShownKey, todayGregorian);
  }

  static String _todayGregorianString() {
    final bdNow = IslamicDateService.nowInBD();
    final y = bdNow.year;
    final m = bdNow.month.toString().padLeft(2, '0');
    final d = bdNow.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
