import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:amol_tracker_app/core/services/islamic_date_service.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('IslamicDateService canonical Hijri pipeline', () {
    test('applies Maghrib boundary as a day rollover', () {
      final maghrib = DateTime(2026, 5, 8, 18, 30);
      final beforeMaghrib = DateTime(2026, 5, 8, 17, 0);
      final afterMaghrib = DateTime(2026, 5, 8, 19, 0);

      final before = IslamicDateService.islamicDateStringForBangladeshMoment(
        beforeMaghrib,
        maghribAtBdMoment: maghrib,
      );
      final after = IslamicDateService.islamicDateStringForBangladeshMoment(
        afterMaghrib,
        maghribAtBdMoment: maghrib,
      );

      expect(
        IslamicDateService.areConsecutiveIslamicDays(before, after),
        isTrue,
      );
    });

    test('applies global -1 Hijri day correction for Gregorian conversion', () {
      final gregorian = DateTime(2026, 5, 8);
      final rawHijri = HijriCalendar.fromDate(gregorian);
      final rawStorage =
          '${rawHijri.hYear}-${rawHijri.hMonth.toString().padLeft(2, '0')}-${rawHijri.hDay.toString().padLeft(2, '0')}';
      final expected = IslamicDateService.shiftStorageByDays(rawStorage, -1);

      final actual = IslamicDateService.islamicDateStringForGregorianDate(
        gregorian,
      );

      expect(actual, expected);
    });

    test('recent Hijri storages stay aligned with corrected today', () {
      final recent =
          IslamicDateService.recentHijriStoragesFromBangladeshCalendar(
            count: 3,
          );
      expect(recent, hasLength(3));

      final today = IslamicDateService.getCurrentIslamicDateStringSafe();
      final yesterday = IslamicDateService.shiftStorageByDays(today, -1);

      expect(recent.first, today);
      expect(recent[1], yesterday);
    });
  });
}
