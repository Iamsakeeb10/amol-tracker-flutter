import 'package:amol_tracker_app/core/utils/quiet_hours_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const overnightQuietFrom = TimeOfDay(hour: 22, minute: 30);
  const overnightQuietTo = TimeOfDay(hour: 5, minute: 0);

  group('QuietHoursHelper.sameDayTimeBeforeQuietHours', () {
    test('app default 12 AM–3 AM leaves standard reminder slots open', () {
      const from = TimeOfDay(hour: 0, minute: 0);
      const to = TimeOfDay(hour: 3, minute: 0);

      expect(
        QuietHoursHelper.isSuppressed(
          const TimeOfDay(hour: 23, minute: 50),
          from: from,
          to: to,
        ),
        isFalse,
      );
      expect(
        QuietHoursHelper.isSuppressed(
          const TimeOfDay(hour: 3, minute: 15),
          from: from,
          to: to,
        ),
        isFalse,
      );
    });

    test('keeps 8:45 PM when quiet hours start at midnight', () {
      const desired = TimeOfDay(hour: 20, minute: 45);
      final at = QuietHoursHelper.sameDayTimeBeforeQuietHours(
        desired,
        from: const TimeOfDay(hour: 0, minute: 0),
        to: overnightQuietTo,
      );
      expect(at, desired);
    });

    test('moves 8:45 PM before an early 8:30 PM quiet window', () {
      const desired = TimeOfDay(hour: 20, minute: 45);
      final at = QuietHoursHelper.sameDayTimeBeforeQuietHours(
        desired,
        from: const TimeOfDay(hour: 20, minute: 30),
        to: overnightQuietTo,
      );
      expect(at, const TimeOfDay(hour: 20, minute: 25));
    });

    test('staggers fallback minutes before quiet-from', () {
      const desired = TimeOfDay(hour: 23, minute: 30);
      final at = QuietHoursHelper.sameDayTimeBeforeQuietHours(
        desired,
        from: overnightQuietFrom,
        to: overnightQuietTo,
        fallbackMinutes: 15,
      );
      expect(at, const TimeOfDay(hour: 22, minute: 15));
    });

    test('returns desired when quiet hours are disabled (from == to)', () {
      const desired = TimeOfDay(hour: 23, minute: 50);
      const closed = TimeOfDay(hour: 22, minute: 30);
      final at = QuietHoursHelper.sameDayTimeBeforeQuietHours(
        desired,
        from: closed,
        to: closed,
      );
      expect(at, desired);
    });

    test('returns null when fallback would cross into the previous day', () {
      const desired = TimeOfDay(hour: 0, minute: 10);
      final at = QuietHoursHelper.sameDayTimeBeforeQuietHours(
        desired,
        from: const TimeOfDay(hour: 0, minute: 3),
        to: const TimeOfDay(hour: 5, minute: 0),
      );
      expect(at, isNull);
    });
  });
}
