import 'package:amol_tracker_app/core/constants/default_amal_fields.dart';
import 'package:amol_tracker_app/core/utils/report_calculator.dart';
import 'package:amol_tracker_app/models/amal_log_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  AmalLogModel log({
    required String date,
    required int score,
    required int maxScore,
    List<String>? activeFieldIds,
    bool specialTimeApplied = false,
  }) {
    return AmalLogModel(
      uid: 'u1',
      displayName: 'Test',
      photoUrl: '',
      isAnonymousDisplay: false,
      hijriDate: date,
      toggles: const {'miswak': true},
      score: score,
      submittedAt: DateTime.utc(2026, 1, 1),
      maxScore: maxScore,
      activeFieldIds: activeFieldIds ?? kLegacyActiveFieldIds,
      specialTimeApplied: specialTimeApplied,
    );
  }

  group('ReportCalculator avgScore normalization', () {
    test('full-max logs keep the same average as raw scores', () {
      final logs = [
        log(date: '1447-01-01', score: 80, maxScore: 100),
        log(date: '1447-01-02', score: 90, maxScore: 100),
        log(date: '1447-01-03', score: 100, maxScore: 100),
      ];
      final summary = ReportCalculator.compute(
        logs: logs,
        fields: kDefaultAmalFields,
        startHijri: '1447-01-01',
        endHijri: '1447-01-03',
        todayStr: '1447-01-10',
        accountCreatedHijri: '1447-01-01',
        locale: 'en',
      );
      // mean(80, 90, 100) == 90; normalized mean of ratios * 100 is also 90
      expect(summary.avgScore, closeTo(90, 0.001));
      expect(summary.hasScoredLogs, isTrue);
    });

    test('special-time reduced max does not unfairly drag average', () {
      final logs = [
        log(date: '1447-01-01', score: 100, maxScore: 100),
        log(
          date: '1447-01-02',
          score: 25,
          maxScore: 25,
          activeFieldIds: const [
            'morning_azkar',
            'evening_azkar',
            'miswak',
          ],
          specialTimeApplied: true,
        ),
      ];
      final summary = ReportCalculator.compute(
        logs: logs,
        fields: kDefaultAmalFields,
        startHijri: '1447-01-01',
        endHijri: '1447-01-02',
        todayStr: '1447-01-10',
        accountCreatedHijri: '1447-01-01',
        locale: 'en',
      );
      // Both days are perfect → average should be 100, not dragged by raw 25
      expect(summary.avgScore, closeTo(100, 0.001));
    });

    test('trendDelta compares normalized averages', () {
      final current = [
        log(date: '1447-02-01', score: 100, maxScore: 100),
        log(date: '1447-02-02', score: 100, maxScore: 100),
      ];
      final previous = [
        log(date: '1447-01-01', score: 50, maxScore: 100),
        log(date: '1447-01-02', score: 50, maxScore: 100),
      ];
      final summary = ReportCalculator.compute(
        logs: current,
        fields: kDefaultAmalFields,
        startHijri: '1447-02-01',
        endHijri: '1447-02-02',
        todayStr: '1447-02-10',
        accountCreatedHijri: '1447-01-01',
        locale: 'en',
        previousPeriodLogs: previous,
      );
      // 100 - 50 = +50
      expect(summary.trendDelta, 50);
    });
  });
}
