import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

/// Hijri calendar helpers using Bangladesh local day (UTC+6).
class HijriHelper {
  HijriHelper._();

  /// "Now" in Bangladesh (UTC+6), used for consistent app-wide Hijri day.
  static DateTime bangladeshNow() {
    return DateTime.now().toUtc().add(const Duration(hours: 6));
  }

  /// Hijri date string for storage and Firestore: `YYYY-MM-DD`.
  static String todayString() {
    final h = HijriCalendar.fromDate(bangladeshNow());
    return _formatStorage(h.hYear, h.hMonth, h.hDay);
  }

  static String _formatStorage(int year, int month, int day) {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year-$m-$d';
  }

  /// Display line e.g. `24 Shawwal 1447`.
  static String todayDisplayString() {
    final cal = HijriCalendar.fromDate(bangladeshNow());
    return '${cal.hDay} ${cal.longMonthName} ${cal.hYear}';
  }

  /// English weekday for the Bangladesh calendar day (e.g. `Sunday`).
  static String todayWeekdayEnglish() {
    return DateFormat('EEEE').format(bangladeshNow());
  }
}
