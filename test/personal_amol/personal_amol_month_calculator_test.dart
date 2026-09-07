import 'package:amol_tracker_app/core/utils/personal_amol_month_calculator.dart';
import 'package:amol_tracker_app/shared/mock/mock_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hijriYear = 1447;
  const hijriMonth = 3;
  const daysInMonth = 30;
  const todayStr = '1447-03-20';
  const accountCreatedHijri = '1447-02-15';

  group('PersonalAmolMonthCalculator', () {
    Map<int, DayCompletion> statesFor(
      Map<String, int> completions,
    ) {
      final days = PersonalAmolMonthCalculator.buildMonth(
        completionsByDay: completions,
        activeCount: 4,
        hijriYear: hijriYear,
        hijriMonth: hijriMonth,
        todayStr: todayStr,
        accountCreatedHijri: accountCreatedHijri,
        daysInMonth: daysInMonth,
      );
      return {for (final d in days) d.day: d.state};
    }

    test('completion ratio maps to community-style thresholds', () {
      final states = statesFor({
        // build uses 'YYYY-MM-DD' keys.
        '1447-03-01': 4, // 4/4 = 1.0 -> full
        '1447-03-02': 3, // 3/4 = 0.75 -> partial
        '1447-03-03': 2, // 2/4 = 0.5 -> partial
        '1447-03-04': 1, // 1/4 = 0.25 -> light
        '1447-03-05': 4, // full (boundary)
        '1447-03-06': 3, // partial
        '1447-03-07': 1, // light
      });
      expect(states[1], DayCompletion.full);
      expect(states[2], DayCompletion.partial);
      expect(states[3], DayCompletion.partial);
      expect(states[4], DayCompletion.light);
      expect(states[5], DayCompletion.full);
      expect(states[6], DayCompletion.partial);
      expect(states[7], DayCompletion.light);
    });

    test('days with zero completions are blank (noData)', () {
      final states = statesFor({'1447-03-01': 2});
      expect(states[2], DayCompletion.noData);
      expect(states[8], DayCompletion.noData);
      expect(states[19], DayCompletion.noData);
    });

    test('future and pre-account days are non-interactive', () {
      // Account created mid-month so the first days of the month precede it.
      const accountHijri = '1447-03-10';
      final days = PersonalAmolMonthCalculator.buildMonth(
        completionsByDay: const {},
        activeCount: 4,
        hijriYear: hijriYear,
        hijriMonth: hijriMonth,
        todayStr: todayStr,
        accountCreatedHijri: accountHijri,
        daysInMonth: daysInMonth,
      );
      final byDay = {for (final d in days) d.day: d};
      expect(byDay[1]!.state, DayCompletion.preAccount);
      expect(byDay[9]!.state, DayCompletion.preAccount);
      expect(byDay[10]!.state, DayCompletion.noData);
      expect(byDay[20]!.state, DayCompletion.today);
      expect(byDay[21]!.state, DayCompletion.future);
      expect(byDay[30]!.state, DayCompletion.future);
    });

    test('zero active count never crashes and renders noData for past days', () {
      final days = PersonalAmolMonthCalculator.buildMonth(
        completionsByDay: const {'1447-03-05': 1},
        activeCount: 0,
        hijriYear: hijriYear,
        hijriMonth: hijriMonth,
        todayStr: todayStr,
        accountCreatedHijri: accountCreatedHijri,
        daysInMonth: daysInMonth,
      );
      final byDay = {for (final d in days) d.day: d};
      expect(byDay[5]!.state, DayCompletion.noData);
    });

    test('today fills realtime when completions exist, else keeps today marker',
        () {
      // Day 20 is today. With no completion it stays a today marker.
      final empty = PersonalAmolMonthCalculator.buildMonth(
        completionsByDay: const {},
        activeCount: 4,
        hijriYear: hijriYear,
        hijriMonth: hijriMonth,
        todayStr: todayStr,
        accountCreatedHijri: accountCreatedHijri,
        daysInMonth: daysInMonth,
      );
      final emptyByDay = {for (final d in empty) d.day: d};
      expect(emptyByDay[20]!.state, DayCompletion.today);

      // Full completion on today -> full fill (gold).
      final full = PersonalAmolMonthCalculator.buildMonth(
        completionsByDay: const {'1447-03-20': 4},
        activeCount: 4,
        hijriYear: hijriYear,
        hijriMonth: hijriMonth,
        todayStr: todayStr,
        accountCreatedHijri: accountCreatedHijri,
        daysInMonth: daysInMonth,
      );
      final fullByDay = {for (final d in full) d.day: d};
      expect(fullByDay[20]!.state, DayCompletion.full);

      // Partial completion on today -> partial fill.
      final partial = PersonalAmolMonthCalculator.buildMonth(
        completionsByDay: const {'1447-03-20': 3},
        activeCount: 4,
        hijriYear: hijriYear,
        hijriMonth: hijriMonth,
        todayStr: todayStr,
        accountCreatedHijri: accountCreatedHijri,
        daysInMonth: daysInMonth,
      );
      final partialByDay = {for (final d in partial) d.day: d};
      expect(partialByDay[20]!.state, DayCompletion.partial);
    });

    test('per-day scheduled denominator scales weekday-only amols', () {
      // Both days are in the past relative to today (1447-03-20).
      const scheduledByDay = <String, int>{
        '1447-03-19': 5, // Thursday
        '1447-03-18': 4, // Wednesday
      };
      // 3 fully-done on a day with 5 due -> ratio 0.6 == partial.
      // 3 fully-done on a day with 4 due -> ratio 0.75 == partial (boundary).
      final days = PersonalAmolMonthCalculator.buildMonth(
        completionsByDay: const {
          '1447-03-19': 3,
          '1447-03-18': 3,
        },
        activeCountByDay: scheduledByDay,
        hijriYear: hijriYear,
        hijriMonth: hijriMonth,
        todayStr: todayStr,
        accountCreatedHijri: accountCreatedHijri,
        daysInMonth: daysInMonth,
      );
      final byDay = {for (final d in days) d.day: d};
      expect(byDay[19]!.state, DayCompletion.partial); // 0.6
      expect(byDay[18]!.state, DayCompletion.partial); // 0.75
    });
  });
}
