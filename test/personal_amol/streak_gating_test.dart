import 'package:amol_tracker_app/core/utils/streak_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const today = '1447-03-21'; // Saturday (weekday index 1)
  const yesterday = '1447-03-20';
  const dayBefore = '1447-03-19';

  group('computeStreakFromLogs (daily, scheduledWeekdays empty)', () {
    test('counts consecutive logged days ending today', () {
      expect(
        computeStreakFromLogs(loggedDates: {today, yesterday, dayBefore},
            todayHijri: today),
        3,
      );
    });

    test('un-logged today falls back to the chain ending yesterday', () {
      expect(
        computeStreakFromLogs(loggedDates: {yesterday}, todayHijri: today),
        1,
      );
    });

    test('gap breaks the chain', () {
      expect(
        computeStreakFromLogs(
            loggedDates: {yesterday, dayBefore, '1447-03-17'}, todayHijri: today),
        2, // 03-18 missing
      );
    });
  });

  group('computeStreakFromLogs (weekday-only, Saturday)', () {
    const saturdayOnly = <int>{1};
    const todayMonday = '1447-03-16'; // Monday, not scheduled

    const allSats = {today, '1447-03-14', '1447-03-07', '1447-02-29'};

    test('unscheduled weekdays neither add to nor break the streak', () {
      expect(
        computeStreakFromLogs(
          loggedDates: allSats,
          todayHijri: today,
          scheduledWeekdays: saturdayOnly,
        ),
        4,
      );
    });

    test('walking from an unscheduled day still counts the run', () {
      final fromMonday = computeStreakFromLogs(
        loggedDates: {'1447-03-14', '1447-03-07', '1447-02-29'},
        todayHijri: todayMonday,
        scheduledWeekdays: saturdayOnly,
      );
      // Today (Monday) is unscheduled; the run of logged Saturdays before it.
      expect(fromMonday, 3);
    });

    test('interior missing scheduled day breaks the chain', () {
      final gap = computeStreakFromLogs(
        loggedDates: {today, '1447-03-07'},
        todayHijri: today,
        scheduledWeekdays: saturdayOnly,
      );
      // 1447-03-14 is scheduled but missing -> chain resets to today only.
      expect(gap, 1);
    });
  });
}