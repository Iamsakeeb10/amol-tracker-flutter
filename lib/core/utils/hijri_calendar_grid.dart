import 'package:hijri/hijri_calendar.dart';

import '../constants/hijri_events.dart';
import '../services/islamic_date_service.dart';

class HijriCalCell {
  const HijriCalCell({
    this.hijriDay,
    this.gregorianDate,
    this.isToday = false,
    this.hasEvent = false,
  });

  const HijriCalCell.empty()
      : hijriDay = null,
        gregorianDate = null,
        isToday = false,
        hasEvent = false;

  final int? hijriDay;
  final DateTime? gregorianDate;
  final bool isToday;
  final bool hasEvent;

  bool get isEmpty => hijriDay == null;
}

/*
Purpose:
Build a Sunday-first Hijri month grid with leading blanks and per-day metadata.

Response:
List of HijriCalCell items sized for a 7-column calendar grid.

Business Rules:
- Week starts on Sunday (Gregorian weekday % 7 offset).
- Today is resolved via canonical Bangladesh Hijri storage key.
- Event days use HijriEvents month/day lookup.

Flow:
1. Compute leading empty cells from the first Hijri day's Gregorian weekday.
2. Append one cell per Hijri day with Gregorian mapping and flags.
3. Return the combined grid list.

Side Effects:
None.

Failure Cases:
Returns only leading blanks when daysInMonth is zero.
*/
class HijriCalendarGridBuilder {
  static List<HijriCalCell> build({
    required int hijriYear,
    required int hijriMonth,
    required String todayStorage,
  }) {
    final cal = HijriCalendar();
    final daysInMonth = cal.getDaysInMonth(hijriYear, hijriMonth);
    final firstGregorian = cal.hijriToGregorian(hijriYear, hijriMonth, 1);
    final leadingBlanks = firstGregorian.weekday % 7;

    final cells = <HijriCalCell>[
      for (var i = 0; i < leadingBlanks; i++) const HijriCalCell.empty(),
    ];

    for (var day = 1; day <= daysInMonth; day++) {
      final gregorian = cal.hijriToGregorian(hijriYear, hijriMonth, day);
      final storage = IslamicDateService.storageFromParts(
        hijriYear,
        hijriMonth,
        day,
      );
      cells.add(
        HijriCalCell(
          hijriDay: day,
          gregorianDate: gregorian,
          isToday: storage == todayStorage,
          hasEvent: HijriEvents.hasEvent(hijriMonth, day),
        ),
      );
    }

    return cells;
  }
}
