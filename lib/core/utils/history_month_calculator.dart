import '../../models/amal_log_model.dart';
import '../../shared/mock/mock_data.dart';
import '../constants/amal_fields.dart' as amal_const;
import '../services/islamic_date_service.dart';
import 'score_calculator.dart';

class HistoryMonthSummary {
  const HistoryMonthSummary({
    required this.logs,
    required this.days,
    required this.consistency,
    required this.avgScore,
    required this.hasScoredLogs,
    required this.weakestAmal,
  });

  final List<AmalLogModel> logs;
  final List<MockDay> days;
  final int consistency;
  final double avgScore;
  final bool hasScoredLogs;
  final ({String id, String label, int misses})? weakestAmal;
}

/*
Purpose:
Pre-compute history calendar days, consistency %, average score, and weakest amal
for a Hijri month so screens do not repeat this work on every rebuild.

Response:
HistoryMonthSummary with virtualized calendar data and derived stats.

Business Rules:
- Pre-account and future days are non-interactive calendar cells.
- Consistency counts only active past logged days at or above 50% max score.
- Weakest amal is the field missed most often across month logs.

Flow:
1. Index logs by Hijri day within the requested month.
2. Build one MockDay per calendar day with completion state.
3. Derive consistency, average score, and weakest amal from logs + fields.

Side Effects:
None — pure computation.

Failure Cases:
Returns empty days when daysInMonth is zero; weakest amal is null when no logs.
*/
class HistoryMonthCalculator {
  static HistoryMonthSummary compute({
    required List<AmalLogModel> logs,
    required List<amal_const.AmalField> fields,
    required int hijriYear,
    required int hijriMonth,
    required String todayStr,
    required String accountCreatedHijri,
    required int daysInMonth,
    required int maxScore,
    required String locale,
  }) {
    final days = _buildDays(
      logs: logs,
      hijriYear: hijriYear,
      hijriMonth: hijriMonth,
      todayStr: todayStr,
      accountCreatedHijri: accountCreatedHijri,
      daysInMonth: daysInMonth,
      maxScore: maxScore,
    );
    final logsWithScore = logs.where((l) => l.score > 0).toList();
    final avgScore = logsWithScore.isEmpty
        ? 0.0
        : logsWithScore.map((l) => l.score).reduce((a, b) => a + b) /
              logsWithScore.length;

    return HistoryMonthSummary(
      logs: logs,
      days: days,
      consistency: _calcConsistency(
        days: days,
        logs: logs,
        maxScore: maxScore,
      ),
      avgScore: avgScore,
      hasScoredLogs: logsWithScore.isNotEmpty,
      weakestAmal: _weakestAmal(logs, fields, locale),
    );
  }

  static List<MockDay> _buildDays({
    required List<AmalLogModel> logs,
    required int hijriYear,
    required int hijriMonth,
    required String todayStr,
    required String accountCreatedHijri,
    required int daysInMonth,
    required int maxScore,
  }) {
    final byDay = <int, AmalLogModel>{};
    for (final log in logs) {
      final segs = log.hijriDate.split('-');
      if (segs.length == 3 &&
          int.parse(segs[0]) == hijriYear &&
          int.parse(segs[1]) == hijriMonth) {
        byDay[int.parse(segs[2])] = log;
      }
    }

    final out = <MockDay>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final key = IslamicDateService.storageFromParts(hijriYear, hijriMonth, d);
      if (key.compareTo(accountCreatedHijri) < 0) {
        out.add(MockDay(day: d, score: 0, state: DayCompletion.preAccount));
        continue;
      }
      final cmp = key.compareTo(todayStr);
      if (cmp > 0) {
        out.add(MockDay(day: d, score: 0, state: DayCompletion.future));
        continue;
      }

      final log = byDay[d];
      if (key == todayStr) {
        final score = log?.score ?? 0;
        var todayState = DayCompletion.today;
        if (log != null) {
          todayState = _scoreToState(score, hasLog: true, maxScore: maxScore);
        }
        out.add(
          MockDay(
            day: d,
            score: score,
            state: todayState,
            isEdited: log?.editedAt != null,
          ),
        );
        continue;
      }

      if (log == null) {
        out.add(MockDay(day: d, score: 0, state: DayCompletion.noData));
        continue;
      }

      final sc = log.score;
      out.add(
        MockDay(
          day: d,
          score: sc,
          state: _scoreToState(sc, hasLog: true, maxScore: maxScore),
          isEdited: log.editedAt != null,
        ),
      );
    }
    return out;
  }

  static DayCompletion _scoreToState(
    int score, {
    required bool hasLog,
    required int maxScore,
  }) {
    if (!hasLog) return DayCompletion.noData;
    final full = (maxScore * 0.8).round();
    final partial = (maxScore * 0.5).round();
    final light = (maxScore * 0.2).round();
    if (score >= full) return DayCompletion.full;
    if (score >= partial) return DayCompletion.partial;
    if (score >= light) return DayCompletion.light;
    if (score >= 1) return DayCompletion.minimal;
    return DayCompletion.miss;
  }

  static int _calcConsistency({
    required List<MockDay> days,
    required List<AmalLogModel> logs,
    required int maxScore,
  }) {
    final activePastDays = days
        .where(
          (d) =>
              d.state != DayCompletion.preAccount &&
              d.state != DayCompletion.future &&
              d.state != DayCompletion.today &&
              d.state != DayCompletion.noData,
        )
        .length;
    if (activePastDays == 0) return 0;

    final halfScore = (maxScore * 0.5).round();
    final logged50Plus = logs.where((l) => l.score >= halfScore).length;
    return ((logged50Plus / activePastDays) * 100).round().clamp(0, 100);
  }

  static ({String id, String label, int misses})? _weakestAmal(
    List<AmalLogModel> logs,
    List<amal_const.AmalField> fields,
    String locale,
  ) {
    if (logs.isEmpty || fields.isEmpty) return null;
    final counts = <String, int>{for (final f in fields) f.id: 0};
    for (final log in logs) {
      for (final f in fields) {
        final isDone = f.type == amal_const.AmalType.numeric
            ? getNumericValue(log.toggles[f.id], f.maxValue) > 0
            : (log.toggles[f.id] == true);
        if (!isDone) counts[f.id] = (counts[f.id] ?? 0) + 1;
      }
    }

    String? maxId;
    var maxC = -1;
    counts.forEach((id, c) {
      if (c > maxC) {
        maxC = c;
        maxId = id;
      }
    });
    if (maxId == null || maxC <= 0) return null;
    final field = fields.firstWhere((f) => f.id == maxId);
    return (id: maxId!, label: field.getLabel(locale), misses: maxC);
  }
}
