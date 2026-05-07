import 'package:adhan_dart/adhan_dart.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';

class IslamicDateService {
  IslamicDateService._();

  static final Coordinates _coords = Coordinates(
    AppConstants.bdLatitude,
    AppConstants.bdLongitude,
  );
  static final CalculationParameters _params =
      CalculationMethodParameters.karachi();

  static DateTime nowInBD() {
    final bdLocation = tz.getLocation(AppConstants.bdTimezone);
    final now = tz.TZDateTime.now(bdLocation);
    return DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
      now.microsecond,
    );
  }

  static DateTime getMaghribTime() {
    final now = nowInBD();
    final prayerTimes = PrayerTimes(
      date: DateTime(now.year, now.month, now.day),
      coordinates: _coords,
      calculationParameters: _params,
    );
    final maghribUtc = prayerTimes.maghrib;
    final maghribBd = maghribUtc.add(const Duration(hours: 6));
    return DateTime(
      maghribBd.year,
      maghribBd.month,
      maghribBd.day,
      maghribBd.hour,
      maghribBd.minute,
      maghribBd.second,
    );
  }

  static DateTime getMaghribTimeSafe() {
    try {
      return getMaghribTime();
    } catch (_) {
      final now = nowInBD();
      return DateTime(now.year, now.month, now.day, 18, 0);
    }
  }

  static bool _isPastMaghrib(DateTime now, DateTime maghrib) {
    return now.isAfter(maghrib.add(const Duration(minutes: 2)));
  }

  static String getCurrentIslamicDateString() {
    final now = nowInBD();
    final maghrib = getMaghribTimeSafe();
    final gregorianForHijri =
        _isPastMaghrib(now, maghrib) ? now.add(const Duration(days: 1)) : now;

    final hijri = HijriCalendar.fromDate(
      DateTime(
        gregorianForHijri.year,
        gregorianForHijri.month,
        gregorianForHijri.day,
      ),
    );

    return _formatStorage(hijri.hYear, hijri.hMonth, hijri.hDay);
  }

  static String getDisplayIslamicDate() {
    final storage = getCurrentIslamicDateString();
    return displayFromStorageBn(storage);
  }

  static String displayFromStorageBn(String hijriYyyyMmDd) {
    final parts = hijriYyyyMmDd.split('-');
    if (parts.length != 3) return hijriYyyyMmDd;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null || m < 1 || m > 12) {
      return hijriYyyyMmDd;
    }

    return '${_toBengaliNumeral(d)} ${_hijriMonthBn(m)} ${_toBengaliNumeral(y)}';
  }

  static String _formatStorage(int year, int month, int day) {
    final mm = month.toString().padLeft(2, '0');
    final dd = day.toString().padLeft(2, '0');
    return '$year-$mm-$dd';
  }

  static String _toBengaliNumeral(int n) {
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return n.toString().split('').map((c) => bn[int.parse(c)]).join();
  }

  static String _hijriMonthBn(int m) {
    const months = [
      '',
      'মুহাররম',
      'সফর',
      'রবিউল আউয়াল',
      'রবিউল আখির',
      'জুমাদাল উলা',
      'জুমাদাল আখিরাহ',
      'রজব',
      'শাবান',
      'রমজান',
      'শাওয়াল',
      'জিলকদ',
      'জিলহজ',
    ];
    return months[m];
  }

  /// Hijri storage key `YYYY-MM-DD` from calendar parts (month 1–12).
  static String storageFromParts(int year, int month, int day) {
    return _formatStorage(year, month, day);
  }

  /// English weekday name for the current Bangladesh-local calendar day.
  static String weekdayEnglishToday() {
    return DateFormat('EEEE').format(nowInBD());
  }

  /// English weekday for the Gregorian day mapped from a Hijri storage key.
  static String weekdayEnglishForStorage(String hijriYyyyMmDd) {
    final parts = hijriYyyyMmDd.split('-');
    if (parts.length != 3) return '';
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return '';
    try {
      final dt = HijriCalendar().hijriToGregorian(y, m, d);
      return DateFormat('EEEE').format(dt);
    } catch (_) {
      return '';
    }
  }

  /// Month title for history headers: Bengali month + Bengali year.
  static String monthYearHeaderBn(int hijriYear, int hijriMonth) {
    if (hijriMonth < 1 || hijriMonth > 12) {
      return _toBengaliNumeral(hijriYear);
    }
    return '${_hijriMonthBn(hijriMonth)} ${_toBengaliNumeral(hijriYear)}';
  }

  /// Past [count] Hijri storage strings from successive Bangladesh calendar days
  /// (same intent as the legacy community date chips).
  static List<String> recentHijriStoragesFromBangladeshCalendar({int count = 7}) {
    final now = nowInBD();
    return List<String>.generate(count, (index) {
      final day = now.subtract(Duration(days: index));
      final h = HijriCalendar.fromDate(DateTime(day.year, day.month, day.day));
      return _formatStorage(h.hYear, h.hMonth, h.hDay);
    });
  }

  /// Whether [later] is exactly one calendar day after [earlier] (Gregorian bridge).
  static bool areConsecutiveIslamicDays(String earlier, String later) {
    try {
      final cal = HijriCalendar();
      final eParts = earlier.split('-');
      final lParts = later.split('-');
      if (eParts.length != 3 || lParts.length != 3) return false;
      final ey = int.parse(eParts[0]);
      final em = int.parse(eParts[1]);
      final ed = int.parse(eParts[2]);
      final ly = int.parse(lParts[0]);
      final lm = int.parse(lParts[1]);
      final ld = int.parse(lParts[2]);
      final eG = cal.hijriToGregorian(ey, em, ed);
      final lG = cal.hijriToGregorian(ly, lm, ld);
      final aa = DateTime(eG.year, eG.month, eG.day);
      final bb = DateTime(lG.year, lG.month, lG.day);
      return bb.difference(aa).inDays == 1;
    } catch (_) {
      return false;
    }
  }

  /// Same as [getCurrentIslamicDateString] with fallbacks for critical paths.
  static String getCurrentIslamicDateStringSafe() {
    try {
      return getCurrentIslamicDateString();
    } catch (_) {
      try {
        final n = nowInBD();
        final h = HijriCalendar.fromDate(DateTime(n.year, n.month, n.day));
        return _formatStorage(h.hYear, h.hMonth, h.hDay);
      } catch (_) {
        final h = HijriCalendar.now();
        return _formatStorage(h.hYear, h.hMonth, h.hDay);
      }
    }
  }
}
