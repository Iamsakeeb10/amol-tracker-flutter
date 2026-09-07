import 'package:amol_tracker_app/core/utils/personal_amol_schedule.dart';
import 'package:amol_tracker_app/models/personal_amol_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PersonalAmolModel amol({
    String id = 'a',
    PersonalAmolFrequency frequency = PersonalAmolFrequency.daily,
    List<int> weekdays = const <int>[],
  }) =>
      PersonalAmolModel(
        id: id,
        name: id,
        icon: '',
        frequency: frequency,
        weekdays: weekdays,
        reminderTime: null,
        isActive: true,
        createdAt: DateTime.utc(2026, 1, 1),
      );

  group('personalAmolScheduledOn', () {
    test('daily amols are always scheduled', () {
      expect(personalAmolScheduledOn(amol(), '1447-03-15'), isTrue);
      expect(personalAmolScheduledOn(amol(), '1447-03-01'), isTrue);
    });

    test('weekday amols are scheduled only on matching weekdays', () {
      // 1447-03-14 is Saturday (index 1), 1447-03-15 is Sunday (index 2).
      final sat = amol(frequency: PersonalAmolFrequency.weekdays, weekdays: [1]);
      expect(personalAmolScheduledOn(sat, '1447-03-14'), isTrue);
      expect(personalAmolScheduledOn(sat, '1447-03-15'), isFalse);
    });
  });

  group('scheduledPersonalAmolByDay', () {
    test('counts scheduled amols per day', () {
      final byDay = scheduledPersonalAmolByDay(
        amols: [
          amol(id: 'daily'),
          amol(id: 'sat', frequency: PersonalAmolFrequency.weekdays,
              weekdays: const [1]),
        ],
        firstHijri: '1447-03-08', // Sunday
        lastHijri: '1447-03-14', // Saturday
      );
      expect(byDay.length, 7);
      expect(byDay['1447-03-08'], 1); // Sun: only daily
      expect(byDay['1447-03-09'], 1); // Mon
      expect(byDay['1447-03-14'], 2); // Sat: daily + sat
    });
  });
}