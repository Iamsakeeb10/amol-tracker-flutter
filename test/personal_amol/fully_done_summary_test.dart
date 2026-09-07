import 'package:amol_tracker_app/models/personal_amol_model.dart';
import 'package:amol_tracker_app/providers/personal_amol_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PersonalAmolModel amol({
    required String id,
    PersonalAmolType type = PersonalAmolType.toggle,
    int target = 1,
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
        type: type,
        target: target,
      );

  PersonalAmolCompletion completion(String amolId, String date, int seq) =>
      PersonalAmolCompletion(
        amolId: amolId,
        hijriDate: date,
        completedAt: DateTime.utc(2026, 1, 1, 0, seq),
      );

  group('fullyDonePersonalAmolByDay', () {
    test('toggle amols count once per completion (legacy semantics)', () {
      final summary = fullyDonePersonalAmolByDay(
        [
          completion('a', '1447-03-01', 1),
          completion('b', '1447-03-01', 2),
          completion('a', '1447-03-02', 3),
        ],
        [
          amol(id: 'a'),
          amol(id: 'b'),
        ],
      );
      expect(summary, {
        '1447-03-01': 2,
        '1447-03-02': 1,
      });
    });

    test('count amol only counts once target is reached', () {
      final summary = fullyDonePersonalAmolByDay(
        [
          // 3 of 5 on day 1 -> not done.
          completion('c', '1447-03-01', 1),
          completion('c', '1447-03-01', 2),
          completion('c', '1447-03-01', 3),
          // 5 of 5 on day 2 -> done.
          completion('c', '1447-03-02', 4),
          completion('c', '1447-03-02', 5),
          completion('c', '1447-03-02', 6),
          completion('c', '1447-03-02', 7),
          completion('c', '1447-03-02', 8),
        ],
        [amol(id: 'c', type: PersonalAmolType.count, target: 5)],
      );
      expect(summary, {
        '1447-03-02': 1,
      });
    });

    test('mixed toggle + count uses per-amol targets', () {
      final summary = fullyDonePersonalAmolByDay(
        [
          completion('toggle', '1447-03-01', 1),
          completion('count', '1447-03-01', 2),
          completion('count', '1447-03-01', 3),
          completion('partial', '1447-03-01', 4),
        ],
        [
          amol(id: 'toggle'),
          amol(id: 'count', type: PersonalAmolType.count, target: 2),
          amol(id: 'partial', type: PersonalAmolType.count, target: 5),
        ],
      );
      // toggle done, count done (2/2), partial not (1/5).
      expect(summary, {'1447-03-01': 2});
    });

    test('no amols or no completions yields empty summary', () {
      expect(fullyDonePersonalAmolByDay([], []), isEmpty);
      expect(
        fullyDonePersonalAmolByDay([completion('a', '1447-03-01', 1)], []),
        isEmpty,
      );
    });

    test('deleted (isActive false) amols still count towards summary', () {
      final summary = fullyDonePersonalAmolByDay(
        [completion('gone', '1447-03-01', 1)],
        [
          amol(id: 'gone', frequency: PersonalAmolFrequency.daily)
              .copyWith(isActive: false),
        ],
      );
      expect(summary, {'1447-03-01': 1});
    });

    test('weekday amol does not count on days it is not scheduled', () {
      // 1447-03-01 is Sunday (index 2), 1447-03-02 is Monday (index 3).
      // Schedule Sunday only.
      final notScheduled = fullyDonePersonalAmolByDay(
        [completion('w', '1447-03-02', 1)],
        [amol(id: 'w', frequency: PersonalAmolFrequency.weekdays, weekdays: [2])],
      );
      expect(notScheduled, isEmpty);

      final scheduled = fullyDonePersonalAmolByDay(
        [completion('w', '1447-03-01', 1)],
        [amol(id: 'w', frequency: PersonalAmolFrequency.weekdays, weekdays: [2])],
      );
      expect(scheduled, {'1447-03-01': 1});
    });
  });
}