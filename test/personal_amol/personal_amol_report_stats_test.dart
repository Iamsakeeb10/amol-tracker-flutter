import 'package:amol_tracker_app/core/services/islamic_date_service.dart';
import 'package:amol_tracker_app/models/personal_amol_model.dart';
import 'package:amol_tracker_app/providers/personal_amol_report_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);

  PersonalAmolModel amol({
    String id = 'a',
    PersonalAmolFrequency frequency = PersonalAmolFrequency.daily,
    List<int> weekdays = const <int>[],
    bool isActive = true,
    PersonalAmolType type = PersonalAmolType.toggle,
    int target = 1,
    DateTime? createdAt,
  }) =>
      PersonalAmolModel(
        id: id,
        name: id,
        icon: 'm:star',
        frequency: frequency,
        weekdays: weekdays,
        reminderTime: null,
        isActive: isActive,
        createdAt: createdAt ?? DateTime.utc(2020, 1, 1),
        type: type,
        target: target,
      );

  PersonalAmolCompletion completion(String amolId, String date, [int seq = 1]) =>
      PersonalAmolCompletion(
        amolId: amolId,
        hijriDate: date,
        completedAt: DateTime.utc(2026, 1, 1, 0, seq),
      );

  group('computePersonalAmolReportStats', () {
    test('returns empty when no amols', () {
      final stats = computePersonalAmolReportStats(
        amols: const [],
        completions: const [],
        startHijri: '1447-03-10',
        endHijri: '1447-03-16',
        todayHijri: '1447-03-20',
      );
      expect(stats, isEmpty);
    });

    test('excludes today from eligible days', () {
      // Period includes today; eligible should stop at yesterday.
      final stats = computePersonalAmolReportStats(
        amols: [amol(id: 'daily')],
        completions: [
          completion('daily', '1447-03-18'),
          completion('daily', '1447-03-19'),
          completion('daily', '1447-03-20'), // today — ignored for eligibility
        ],
        startHijri: '1447-03-18',
        endHijri: '1447-03-20',
        todayHijri: '1447-03-20',
      );
      expect(stats, hasLength(1));
      expect(stats.first.eligibleDays, 2); // 18 + 19 only
      expect(stats.first.completedDays, 2);
      expect(stats.first.rate, 1.0);
    });

    test('includeToday counts incomplete today and lowers rate', () {
      // Yesterday full, today miss (no completion) after community submit.
      final stats = computePersonalAmolReportStats(
        amols: [amol(id: 'daily')],
        completions: [completion('daily', '1447-03-19')],
        startHijri: '1447-03-19',
        endHijri: '1447-03-20',
        todayHijri: '1447-03-20',
        includeToday: true,
      );
      expect(stats, hasLength(1));
      expect(stats.first.eligibleDays, 2);
      expect(stats.first.completedDays, 1);
      expect(stats.first.rate, 0.5);
    });

    test('includeToday counts partial count-type day as incomplete', () {
      final stats = computePersonalAmolReportStats(
        amols: [
          amol(id: 'count', type: PersonalAmolType.count, target: 5),
        ],
        completions: [
          completion('count', '1447-03-19', 1),
          completion('count', '1447-03-19', 2),
          completion('count', '1447-03-19', 3),
          completion('count', '1447-03-19', 4),
          completion('count', '1447-03-19', 5),
          // today only 4/5
          completion('count', '1447-03-20', 1),
          completion('count', '1447-03-20', 2),
          completion('count', '1447-03-20', 3),
          completion('count', '1447-03-20', 4),
        ],
        startHijri: '1447-03-19',
        endHijri: '1447-03-20',
        todayHijri: '1447-03-20',
        includeToday: true,
      );
      expect(stats.first.eligibleDays, 2);
      expect(stats.first.completedDays, 1);
      expect(stats.first.rate, 0.5);
    });

    test('includeToday with full today keeps 100%', () {
      final stats = computePersonalAmolReportStats(
        amols: [amol(id: 'daily')],
        completions: [
          completion('daily', '1447-03-19'),
          completion('daily', '1447-03-20'),
        ],
        startHijri: '1447-03-19',
        endHijri: '1447-03-20',
        todayHijri: '1447-03-20',
        includeToday: true,
      );
      expect(stats.first.eligibleDays, 2);
      expect(stats.first.completedDays, 2);
      expect(stats.first.rate, 1.0);
    });

    test('mid-period creation starts eligibility at createdAt Hijri day', () {
      // BD calendar date → Hijri storage floor for eligibility.
      final created = DateTime(2025, 9, 12);
      final createdHijri =
          IslamicDateService.hijriStorageForAccountCreated(created);
      final stats = computePersonalAmolReportStats(
        amols: [amol(id: 'new', createdAt: created)],
        completions: const [],
        startHijri: '1447-03-01',
        endHijri: '1447-03-20',
        todayHijri: '1447-03-25',
      );
      expect(stats, hasLength(1));
      // Full period would be 20 days; creation mid-way must shrink eligibility
      // to days on/after the BD Hijri creation day through 1447-03-20.
      var expected = 0;
      var cursor = createdHijri.compareTo('1447-03-01') < 0
          ? '1447-03-01'
          : createdHijri;
      while (cursor.compareTo('1447-03-20') <= 0) {
        expected++;
        final next = IslamicDateService.shiftStorageByDays(cursor, 1);
        if (next == cursor || next.compareTo(cursor) <= 0) break;
        cursor = next;
      }
      expect(stats.first.eligibleDays, expected);
    });

    test('weekday amols only count scheduled weekdays', () {
      // 1447-03-14 Sat (1) … 1447-03-20 Fri (7). Saturday-only amol.
      final stats = computePersonalAmolReportStats(
        amols: [
          amol(
            id: 'sat',
            frequency: PersonalAmolFrequency.weekdays,
            weekdays: const [1],
          ),
        ],
        completions: [completion('sat', '1447-03-14')],
        startHijri: '1447-03-14',
        endHijri: '1447-03-20',
        todayHijri: '1447-03-21',
      );
      expect(stats, hasLength(1));
      expect(stats.first.eligibleDays, 1); // only Saturday
      expect(stats.first.completedDays, 1);
      expect(stats.first.rate, 1.0);
    });

    test('count type requires target completions for a completed day', () {
      final stats = computePersonalAmolReportStats(
        amols: [
          amol(id: 'count', type: PersonalAmolType.count, target: 3),
        ],
        completions: [
          completion('count', '1447-03-18', 1),
          completion('count', '1447-03-18', 2),
          // only 2 of 3 on 18th → not completed
          completion('count', '1447-03-19', 1),
          completion('count', '1447-03-19', 2),
          completion('count', '1447-03-19', 3),
        ],
        startHijri: '1447-03-18',
        endHijri: '1447-03-19',
        todayHijri: '1447-03-20',
      );
      expect(stats, hasLength(1));
      expect(stats.first.eligibleDays, 2);
      expect(stats.first.completedDays, 1);
      expect(stats.first.totalCompletions, 5);
      expect(stats.first.rate, 0.5);
    });

    test('soft-deleted without completions is excluded', () {
      final stats = computePersonalAmolReportStats(
        amols: [amol(id: 'gone', isActive: false)],
        completions: const [],
        startHijri: '1447-03-10',
        endHijri: '1447-03-16',
        todayHijri: '1447-03-20',
      );
      expect(stats, isEmpty);
    });

    test('soft-deleted with completions is included', () {
      final stats = computePersonalAmolReportStats(
        amols: [amol(id: 'gone', isActive: false)],
        completions: [completion('gone', '1447-03-15')],
        startHijri: '1447-03-14',
        endHijri: '1447-03-16',
        todayHijri: '1447-03-20',
      );
      expect(stats, hasLength(1));
      expect(stats.first.isActive, isFalse);
      expect(stats.first.completedDays, 1);
      expect(stats.first.eligibleDays, 3);
    });

    test('soft-deleted with unscheduled completions shows 0% row', () {
      final stats = computePersonalAmolReportStats(
        amols: [
          amol(
            id: 'gone',
            isActive: false,
            frequency: PersonalAmolFrequency.weekdays,
            weekdays: const [], // never scheduled
          ),
        ],
        completions: [completion('gone', '1447-03-15')],
        startHijri: '1447-03-14',
        endHijri: '1447-03-16',
        todayHijri: '1447-03-20',
      );
      expect(stats, hasLength(1));
      expect(stats.first.eligibleDays, 0);
      expect(stats.first.completedDays, 0);
      expect(stats.first.totalCompletions, 1);
      expect(stats.first.rate, 0.0);
    });

    test('sorts by descending rate', () {
      final stats = computePersonalAmolReportStats(
        amols: [amol(id: 'low'), amol(id: 'high')],
        completions: [
          completion('high', '1447-03-14'),
          completion('high', '1447-03-15'),
          completion('low', '1447-03-14'),
        ],
        startHijri: '1447-03-14',
        endHijri: '1447-03-15',
        todayHijri: '1447-03-20',
      );
      expect(stats.map((s) => s.amolId).toList(), ['high', 'low']);
    });

    test('ignores completions outside report range', () {
      final stats = computePersonalAmolReportStats(
        amols: [amol(id: 'daily')],
        completions: [
          completion('daily', '1447-03-10'),
          completion('daily', '1447-03-15'),
          completion('daily', '1447-03-20'),
        ],
        startHijri: '1447-03-14',
        endHijri: '1447-03-16',
        todayHijri: '1447-03-20',
      );
      expect(stats.first.totalCompletions, 1);
      expect(stats.first.completedDays, 1);
    });

    test('toggle over-completion still counts one completed day', () {
      final stats = computePersonalAmolReportStats(
        amols: [amol(id: 'toggle')],
        completions: [
          completion('toggle', '1447-03-15', 1),
          completion('toggle', '1447-03-15', 2),
        ],
        startHijri: '1447-03-15',
        endHijri: '1447-03-15',
        todayHijri: '1447-03-20',
      );
      expect(stats.first.completedDays, 1);
      expect(stats.first.totalCompletions, 2);
      expect(stats.first.rate, 1.0);
    });

    test('zero eligible days yields zero rate without division error', () {
      // Period entirely in the future relative to yesterday.
      final stats = computePersonalAmolReportStats(
        amols: [amol(id: 'daily')],
        completions: const [],
        startHijri: '1447-03-20',
        endHijri: '1447-03-20',
        todayHijri: '1447-03-20',
      );
      expect(stats, isEmpty);
    });
  });
}
