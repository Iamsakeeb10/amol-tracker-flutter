import 'package:amol_tracker_app/core/utils/notification_day_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hasLoggedCurrentIslamicDay', () {
    test('is true only when lastLogDate is today', () {
      expect(
        hasLoggedCurrentIslamicDay(
          todayHijri: '1447-11-15',
          lastLogDate: '1447-11-15',
        ),
        isTrue,
      );
    });

    test('is false when the user only logged yesterday', () {
      expect(
        hasLoggedCurrentIslamicDay(
          todayHijri: '1447-11-15',
          lastLogDate: '1447-11-14',
        ),
        isFalse,
      );
    });

    test('is false when lastLogDate is empty', () {
      expect(
        hasLoggedCurrentIslamicDay(todayHijri: '1447-11-15', lastLogDate: ''),
        isFalse,
      );
    });
  });

  group('evening reminder policy', () {
    test('uses early evening close and last-chance slots', () {
      expect(eveningCloseReminderTime, const TimeOfDay(hour: 20, minute: 0));
      expect(
        eveningLastChanceReminderTime,
        const TimeOfDay(hour: 20, minute: 45),
      );
    });

    test('skips 8 PM when daily reminder is within 45 minutes', () {
      expect(
        shouldScheduleEveningClose(
          dailyEveningReminderEnabled: true,
          dailyEveningReminderTime: const TimeOfDay(hour: 19, minute: 15),
        ),
        isFalse,
      );
      expect(
        shouldScheduleEveningClose(
          dailyEveningReminderEnabled: true,
          dailyEveningReminderTime: const TimeOfDay(hour: 19, minute: 14),
        ),
        isTrue,
      );
    });

    test('keeps 8 PM when the daily evening reminder is disabled', () {
      expect(
        shouldScheduleEveningClose(
          dailyEveningReminderEnabled: false,
          dailyEveningReminderTime: const TimeOfDay(hour: 20, minute: 0),
        ),
        isTrue,
      );
    });

    test('skips 8:45 PM beside a custom 8:30–9 PM reminder', () {
      for (final time in [
        const TimeOfDay(hour: 20, minute: 30),
        const TimeOfDay(hour: 20, minute: 45),
        const TimeOfDay(hour: 21, minute: 0),
      ]) {
        expect(
          shouldScheduleEveningLastChance(
            dailyEveningReminderEnabled: true,
            hasCustomEveningTime: true,
            dailyEveningReminderTime: time,
          ),
          isFalse,
        );
      }
    });

    test('allows one catch-up from 8:45 PM until before 10 PM', () {
      expect(
        shouldScheduleEveningCatchUp(const TimeOfDay(hour: 20, minute: 44)),
        isFalse,
      );
      expect(
        shouldScheduleEveningCatchUp(const TimeOfDay(hour: 20, minute: 45)),
        isTrue,
      );
      expect(
        shouldScheduleEveningCatchUp(const TimeOfDay(hour: 21, minute: 59)),
        isTrue,
      );
      expect(
        shouldScheduleEveningCatchUp(const TimeOfDay(hour: 22, minute: 0)),
        isFalse,
      );
    });
  });
}
