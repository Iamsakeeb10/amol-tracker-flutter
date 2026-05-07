import 'package:adhan_dart/adhan_dart.dart';
import 'package:hijri/hijri_calendar.dart';
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
}
