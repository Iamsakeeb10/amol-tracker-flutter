import 'package:amol_tracker_app/core/utils/personal_amol_schedule.dart';
import 'package:amol_tracker_app/models/personal_amol_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PersonalAmolModel amol({
    String id = 'a',
    PersonalAmolFrequency frequency = PersonalAmolFrequency.daily,
    List<int> weekdays = const <int>[],
    bool isActive = true,
  }) =>
      PersonalAmolModel(
        id: id,
        name: id,
        icon: '',
        frequency: frequency,
        weekdays: weekdays,
        reminderTime: null,
        isActive: isActive,
        createdAt: DateTime.utc(2026, 1, 1),
      );

  PersonalAmolCompletion completion(String amolId, String date, int seq) =>
      PersonalAmolCompletion(
        amolId: amolId,
        hijriDate: date,
        completedAt: DateTime.utc(2026, 1, 1, 0, seq),
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

    test('soft-deleted amol counts only on days it was completed', () {
      final byDay = scheduledPersonalAmolByDay(
        amols: [
          amol(id: 'active'),
          amol(id: 'gone', isActive: false),
        ],
        firstHijri: '1447-03-18',
        lastHijri: '1447-03-20',
        today: '1447-03-20',
        completions: [
          // Deleted amol only has history on the 18th.
          completion('gone', '1447-03-18', 1),
        ],
      );
      // 18th: deleted amol has a completion -> counts.
      expect(byDay['1447-03-18'], 2);
      // 19th: no completion for the deleted amol -> does not dilute.
      expect(byDay['1447-03-19'], 1);
      // 20th (today): deleted amols make no demands at all.
      expect(byDay['1447-03-20'], 1);
    });

    test('deleted amol with no completions never dilutes past days', () {
      final byDay = scheduledPersonalAmolByDay(
        amols: [
          amol(id: 'active'),
          amol(id: 'gone', isActive: false),
        ],
        firstHijri: '1447-03-18',
        lastHijri: '1447-03-20',
        today: '1447-03-20',
      );
      expect(byDay['1447-03-18'], 1);
      expect(byDay['1447-03-19'], 1);
      expect(byDay['1447-03-20'], 1);
    });

    test('regression: two active + two deleted keeps 100% day full', () {
      // Mirrors the reported bug: 2 active daily amols fully done, plus 2
      // soft-deleted amols with no completions that day. scheduled must be 2
      // so the done/scheduled ratio reaches full instead of 25%.
      final byDay = scheduledPersonalAmolByDay(
        amols: [
          amol(id: 'count', isActive: true),
          amol(id: 'toggle', isActive: true),
          amol(id: 'gone1', isActive: false),
          amol(id: 'gone2', isActive: false),
        ],
        firstHijri: '1447-03-25',
        lastHijri: '1447-03-25',
        today: '1447-03-26',
        completions: [
          completion('count', '1447-03-25', 1),
          completion('toggle', '1447-03-25', 2),
        ],
      );
      expect(byDay['1447-03-25'], 2);
    });
  });

  group('historicalPersonalAmolForDay', () {
    test('includes inactive amols with a completion on that day', () {
      final list = historicalPersonalAmolForDay(
        amols: [
          amol(id: 'gone', isActive: false),
          amol(id: 'active', isActive: true),
        ],
        hijriDate: '1447-03-18',
        completions: [completion('gone', '1447-03-18', 1)],
      );
      expect(list.map((a) => a.id), ['gone']);
    });

    test('excludes inactive amols with no completion that day', () {
      final list = historicalPersonalAmolForDay(
        amols: [amol(id: 'gone', isActive: false)],
        hijriDate: '1447-03-18',
        completions: [completion('gone', '1447-03-19', 1)],
      );
      expect(list, isEmpty);
    });

    test('never includes active amols', () {
      final list = historicalPersonalAmolForDay(
        amols: [amol(id: 'active', isActive: true)],
        hijriDate: '1447-03-18',
        completions: [completion('active', '1447-03-18', 1)],
      );
      expect(list, isEmpty);
    });
  });
}