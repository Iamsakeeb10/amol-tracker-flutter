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
    return islamicDateStringForBangladeshMoment(
      now,
      maghribAtBdMoment: maghrib,
    );
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

  /// Canonical conversion for Bangladesh local moment.
  /// Flow: BD now -> Maghrib boundary -> Hijri conversion -> global day adjustment.
  static String islamicDateStringForBangladeshMoment(
    DateTime bdNow, {
    DateTime? maghribAtBdMoment,
  }) {
    final maghrib = maghribAtBdMoment ?? getMaghribTimeSafe();
    final gregorianBase = _isPastMaghrib(bdNow, maghrib)
        ? bdNow.add(const Duration(days: 1))
        : bdNow;
    return islamicDateStringForGregorianDate(gregorianBase);
  }

  /// Canonical conversion for a Gregorian date with global Hijri adjustment.
  static String islamicDateStringForGregorianDate(DateTime gregorianDate) {
    final gregorianOnly = DateTime(
      gregorianDate.year,
      gregorianDate.month,
      gregorianDate.day,
    );
    final hijri = HijriCalendar.fromDate(gregorianOnly);
    return _adjustHijriStorageByDays(
      _formatStorage(hijri.hYear, hijri.hMonth, hijri.hDay),
      AppConstants.hijriDayAdjustment,
    );
  }

  /// Hijri year/month for the canonical "current" Islamic day.
  static ({int year, int month}) currentHijriYearMonth() {
    final cur = getCurrentIslamicDateStringSafe();
    final parts = cur.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y != null && m != null && m >= 1 && m <= 12) {
        return (year: y, month: m);
      }
    }
    final now = nowInBD();
    final fallback = islamicDateStringForGregorianDate(now);
    final fParts = fallback.split('-');
    if (fParts.length == 3) {
      final y = int.tryParse(fParts[0]) ?? 1440;
      final m = int.tryParse(fParts[1]) ?? 1;
      final month = m < 1 ? 1 : (m > 12 ? 12 : m);
      return (year: y, month: month);
    }
    return (year: 1440, month: 1);
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
  static List<String> recentHijriStoragesFromBangladeshCalendar({
    int count = 7,
  }) {
    final today = getCurrentIslamicDateStringSafe();
    return List<String>.generate(
      count,
      (index) => shiftStorageByDays(today, -index),
    );
  }

  /// Shift a Hijri storage key by [days] using Gregorian bridge.
  static String shiftStorageByDays(String hijriYyyyMmDd, int days) {
    final parts = hijriYyyyMmDd.split('-');
    if (parts.length != 3) return hijriYyyyMmDd;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return hijriYyyyMmDd;
    try {
      final g = HijriCalendar().hijriToGregorian(y, m, d);
      final shifted = DateTime(
        g.year,
        g.month,
        g.day,
      ).add(Duration(days: days));
      final hs = HijriCalendar.fromDate(shifted);
      return _formatStorage(hs.hYear, hs.hMonth, hs.hDay);
    } catch (_) {
      return hijriYyyyMmDd;
    }
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
        return islamicDateStringForGregorianDate(n);
      } catch (_) {
        final h = HijriCalendar.now();
        return _adjustHijriStorageByDays(
          _formatStorage(h.hYear, h.hMonth, h.hDay),
          AppConstants.hijriDayAdjustment,
        );
      }
    }
  }

  static String _adjustHijriStorageByDays(String storage, int days) {
    if (days == 0) return storage;
    return shiftStorageByDays(storage, days);
  }

  /// Bangladesh-local moment for any [source] instant (UTC-safe).
  static DateTime bangladeshDateTimeFrom(DateTime source) {
    final bdLocation = tz.getLocation(AppConstants.bdTimezone);
    final utc = source.toUtc();
    final bd = tz.TZDateTime.fromMillisecondsSinceEpoch(
      bdLocation,
      utc.millisecondsSinceEpoch,
    );
    return DateTime(
      bd.year,
      bd.month,
      bd.day,
      bd.hour,
      bd.minute,
      bd.second,
      bd.millisecond,
      bd.microsecond,
    );
  }

  /// Calendar date in Asia/Dhaka (no Maghrib rollover).
  static DateTime bangladeshCalendarDateOnly(DateTime source) {
    final bd = bangladeshDateTimeFrom(source);
    return DateTime(bd.year, bd.month, bd.day);
  }

  /// Hijri storage for account-creation floor (BD calendar, not device local).
  static String hijriStorageForAccountCreated(DateTime createdAt) {
    return islamicDateStringForGregorianDate(
      bangladeshCalendarDateOnly(createdAt),
    );
  }

  /// Returns true if [targetDate] is one of the past [windowDays] Hijri days
  /// before [todayDate] (same chain as [shiftStorageByDays] / history calendar).
  /// Does not include today.
  static bool isWithinEditWindow(
    String targetDate,
    String todayDate,
    int windowDays,
  ) {
    if (targetDate == todayDate) return false;
    for (var i = 1; i <= windowDays; i++) {
      if (shiftStorageByDays(todayDate, -i) == targetDate) {
        return true;
      }
    }
    return false;
  }

  /// Past [windowDays] editable Hijri keys (excludes today).
  static List<String> editableHijriStoragesBeforeToday(
    String todayDate, {
    int windowDays = 6,
  }) {
    return List<String>.generate(
      windowDays,
      (i) => shiftStorageByDays(todayDate, -(i + 1)),
    );
  }
}
