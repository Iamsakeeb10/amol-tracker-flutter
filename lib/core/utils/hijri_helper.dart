import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../services/islamic_date_service.dart';

/// Hijri calendar helpers using Bangladesh local day (UTC+6).
class HijriHelper {
  HijriHelper._();

  /// "Now" in Bangladesh, used for consistent app-wide Hijri day.
  static DateTime bangladeshNow() {
    return IslamicDateService.nowInBD();
  }

  /// Hijri date string for storage and Firestore: `YYYY-MM-DD`.
  static String todayString() {
    return IslamicDateService.getCurrentIslamicDateStringSafe();
  }

  static String _formatStorage(int year, int month, int day) {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year-$m-$d';
  }

  /// Display line using Bengali numerals/month names.
  static String todayDisplayString() {
    return IslamicDateService.getDisplayIslamicDate();
  }

  /// English weekday for the Bangladesh calendar day (e.g. `Sunday`).
  static String todayWeekdayEnglish() {
    return DateFormat('EEEE').format(bangladeshNow());
  }

  /// Hijri `YYYY-MM-DD` from parts (month 1–12, day 1–29/30).
  static String storageFromParts(int year, int month, int day) {
    return _formatStorage(year, month, day);
  }

  /// e.g. `Shawwal 1447` for display headers (uses first day of month for month name).
  static String monthYearDisplay(int hijriYear, int hijriMonth) {
    final base = HijriCalendar();
    final gDate = base.hijriToGregorian(hijriYear, hijriMonth, 1);
    final cal = HijriCalendar.fromDate(gDate);
    return '${cal.longMonthName} ${cal.hYear}';
  }

  /// Bengali display for a storage key.
  static String displayFromStorage(String hijriYyyyMmDd) {
    return IslamicDateService.displayFromStorageBn(hijriYyyyMmDd);
  }

  /// English weekday name for a Hijri calendar date (Bangladesh-local Gregorian mapping).
  static String weekdayEnglishForHijriStorage(String hijriYyyyMmDd) {
    final parts = hijriYyyyMmDd.split('-');
    if (parts.length != 3) return '';
    final y = int.parse(parts[0], radix: 10);
    final m = int.parse(parts[1], radix: 10);
    final d = int.parse(parts[2], radix: 10);
    final cal = HijriCalendar();
    final dt = cal.hijriToGregorian(y, m, d);
    return DateFormat('EEEE').format(dt);
  }
}
