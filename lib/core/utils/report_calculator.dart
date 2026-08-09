import '../constants/amal_fields.dart' as amal_const;
import '../services/islamic_date_service.dart';
import '../../models/amal_log_model.dart';
import 'score_calculator.dart';

/// One day (or aggregated bucket) for the report score chart.
class ReportBarPoint {
  const ReportBarPoint({
    required this.label,
    required this.score,
    required this.hasLog,
    required this.maxScore,
    required this.specialTimeApplied,
    this.hijriDate,
  });

  final String label;
  final int score;
  final bool hasLog;
  final int maxScore;
  final bool specialTimeApplied;
  final String? hijriDate;
}

/// Per-amal completion stats for the report breakdown list.
class ReportAmalStat {
  const ReportAmalStat({
    required this.id,
    required this.label,
    required this.doneCount,
    required this.eligibleDays,
    required this.rate,
  });

  final String id;
  final String label;
  final int doneCount;
  final int eligibleDays;
  final double rate;
}

/// Optional community rank for the *current* live period only.
class ReportRankInfo {
  const ReportRankInfo({
    required this.rank,
    required this.totalParticipants,
    this.topScore,
    this.userScore,
  });

  final int rank;
  final int totalParticipants;
  final int? topScore;
  final int? userScore;
}

class ReportSummary {
  const ReportSummary({
    required this.startHijri,
    required this.endHijri,
    required this.logs,
    required this.daysLogged,
    required this.eligibleDays,
    required this.avgScore,
    required this.hasScoredLogs,
    required this.consistency,
    required this.bestStreakInPeriod,
    required this.bars,
    required this.amalBreakdown,
    required this.includesToday,
    this.bestDayScore,
    this.bestDayHijri,
    this.bestDayWeekday,
    this.weakestAmal,
    this.strongestAmal,
    this.liveCurrentStreak,
    this.trendDelta,
    this.rankInfo,
    this.hadithText,
  });

  final String startHijri;
  final String endHijri;
  final List<AmalLogModel> logs;
  final int daysLogged;
  final int eligibleDays;
  final double avgScore;
  final bool hasScoredLogs;
  final int consistency;
  final int bestStreakInPeriod;
  final List<ReportBarPoint> bars;
  final List<ReportAmalStat> amalBreakdown;
  final bool includesToday;
  final int? bestDayScore;
  final String? bestDayHijri;
  final String? bestDayWeekday;
  final ReportAmalStat? weakestAmal;
  final ReportAmalStat? strongestAmal;
  final int? liveCurrentStreak;
  final int? trendDelta;
  final ReportRankInfo? rankInfo;
  final String? hadithText;
}

/*
Purpose:
Pure computation of weekly/monthly/custom report metrics from amal logs.

Response:
ReportSummary with averages, consistency, amal breakdown, chart bars, insights.

Business Rules:
- Only days with a submitted log count as "logged".
- Today is excluded from averages/consistency until submitted.
- Future and pre-account days are never eligible.
- Avg score uses only logs with score > 0.
- Consistency = share of eligible logged days at ≥ 50% of max score.
- Community rank is attached only when the caller provides [rankInfo].

Flow:
1. Build the ordered Hijri day list for [startHijri]..[endHijri].
2. Index logs and compute day-level stats.
3. Derive amal breakdown, streak, bars, and optional trend delta.

Side Effects:
None — pure computation.

Failure Cases:
Empty range / no eligible days → zeros and null optional insights.
*/
class ReportCalculator {
  static const int maxCustomDays = 90;
  static const int bucketThresholdDays = 14;

  static ReportSummary compute({
    required List<AmalLogModel> logs,
    required List<amal_const.AmalField> fields,
    required String startHijri,
    required String endHijri,
    required String todayStr,
    required String accountCreatedHijri,
    required String locale,
    List<AmalLogModel> previousPeriodLogs = const [],
    ReportRankInfo? rankInfo,
    int? liveCurrentStreak,
    List<String> hadithTexts = const [],
    String? periodKey,
  }) {
    final dayKeys = _enumerateDays(startHijri, endHijri);
    final byDate = <String, AmalLogModel>{
      for (final log in logs) log.hijriDate: log,
    };

    final eligibleKeys = <String>[];
    final loggedKeys = <String>[];
    for (final key in dayKeys) {
      if (key.compareTo(accountCreatedHijri) < 0) continue;
      if (key.compareTo(todayStr) > 0) continue;
      if (key == todayStr && !byDate.containsKey(key)) continue;
      eligibleKeys.add(key);
      if (byDate.containsKey(key)) loggedKeys.add(key);
    }

    final scoredLogs = logs.where((l) {
      if (l.hijriDate.compareTo(startHijri) < 0) return false;
      if (l.hijriDate.compareTo(endHijri) > 0) return false;
      if (l.hijriDate == todayStr) {
        // Include today's submitted log in averages.
      } else if (l.hijriDate.compareTo(todayStr) > 0) {
        return false;
      }
      return l.score > 0;
    }).toList();

    final avgScore = scoredLogs.isEmpty
        ? 0.0
        : scoredLogs
                .map((l) => l.maxScore > 0 ? (l.score / l.maxScore) * 100 : 0.0)
                .reduce((a, b) => a + b) /
            scoredLogs.length;

    AmalLogModel? bestLog;
    for (final log in scoredLogs) {
      if (bestLog == null || log.score > bestLog.score) bestLog = log;
    }

    final consistentCount = loggedKeys
        .where((k) {
          final log = byDate[k];
          if (log == null) return false;
          final halfScore = (log.maxScore * 0.5).round().clamp(1, log.maxScore);
          return log.score >= halfScore;
        })
        .length;
    final consistency = eligibleKeys.isEmpty
        ? 0
        : ((consistentCount / eligibleKeys.length) * 100).round().clamp(0, 100);

    final amalBreakdown = _amalBreakdown(
      logs: loggedKeys.map((k) => byDate[k]!).toList(),
      fields: fields,
      locale: locale,
      totalEligibleDays: eligibleKeys.length,
    );

    ReportAmalStat? weakest;
    ReportAmalStat? strongest;
    if (amalBreakdown.isNotEmpty && loggedKeys.isNotEmpty) {
      final sorted = List<ReportAmalStat>.from(amalBreakdown)
        ..sort((a, b) => a.rate.compareTo(b.rate));
      weakest = sorted.first.rate < 1.0 ? sorted.first : null;
      strongest = sorted.last.rate > 0.0 ? sorted.last : null;
      if (weakest != null &&
          strongest != null &&
          weakest.id == strongest.id) {
        // Single field — keep strongest, drop weakest duplicate insight.
        weakest = weakest.rate < 1.0 ? weakest : null;
        if (weakest?.id == strongest.id) strongest = null;
      }
    }

    final includesToday =
        todayStr.compareTo(startHijri) >= 0 &&
        todayStr.compareTo(endHijri) <= 0;

    final bars = _buildBars(
      dayKeys: dayKeys,
      byDate: byDate,
      todayStr: todayStr,
      accountCreatedHijri: accountCreatedHijri,
      locale: locale,
    );

    int? trendDelta;
    final prevScored = previousPeriodLogs.where((l) => l.score > 0).toList();
    if (scoredLogs.isNotEmpty && prevScored.isNotEmpty) {
      final prevAvg = prevScored
              .map((l) => l.maxScore > 0 ? (l.score / l.maxScore) * 100 : 0.0)
              .reduce((a, b) => a + b) /
          prevScored.length;
      trendDelta = (avgScore - prevAvg).round();
    }

    final hadith = _pickHadith(hadithTexts, periodKey ?? '$startHijri|$endHijri');

    return ReportSummary(
      startHijri: startHijri,
      endHijri: endHijri,
      logs: logs,
      daysLogged: loggedKeys.length,
      eligibleDays: eligibleKeys.length,
      avgScore: avgScore,
      hasScoredLogs: scoredLogs.isNotEmpty,
      consistency: consistency,
      bestStreakInPeriod: _bestStreak(loggedKeys),
      bars: bars,
      amalBreakdown: amalBreakdown,
      includesToday: includesToday,
      bestDayScore: bestLog?.score,
      bestDayHijri: bestLog?.hijriDate,
      bestDayWeekday: bestLog == null
          ? null
          : _weekdayForStorage(bestLog.hijriDate, locale),
      weakestAmal: weakest,
      strongestAmal: strongest,
      liveCurrentStreak: includesToday ? liveCurrentStreak : null,
      trendDelta: trendDelta,
      rankInfo: rankInfo,
      hadithText: hadith,
    );
  }

  static List<String> _enumerateDays(String start, String end) {
    if (start.isEmpty || end.isEmpty) return const [];
    final from = start.compareTo(end) <= 0 ? start : end;
    final to = start.compareTo(end) <= 0 ? end : start;
    final out = <String>[];
    var cursor = from;
    // Hard cap guards against pathological ranges.
    for (var i = 0; i < maxCustomDays + 7; i++) {
      out.add(cursor);
      if (cursor == to) break;
      final next = IslamicDateService.shiftStorageByDays(cursor, 1);
      if (next == cursor || next.compareTo(cursor) <= 0) break;
      cursor = next;
    }
    return out;
  }

  static List<ReportAmalStat> _amalBreakdown({
    required List<AmalLogModel> logs,
    required List<amal_const.AmalField> fields,
    required String locale,
    required int totalEligibleDays,
  }) {
    final fieldMap = <String, amal_const.AmalField>{};
    for (final f in fields) {
      if (f.isActive && f.id.isNotEmpty) fieldMap[f.id] = f;
    }

    final eligible = totalEligibleDays;
    if (eligible == 0) {
      return fieldMap.values
          .map(
            (f) => ReportAmalStat(
              id: f.id,
              label: f.getLabel(locale),
              doneCount: 0,
              eligibleDays: 0,
              rate: 0,
            ),
          )
          .toList();
    }

    final done = <String, int>{};
    final numericSums = <String, int>{};
    // Logged days where a field was inactive (e.g. special-time disabled)
    // must not count against that field's completion rate.
    final inactiveLoggedDays = <String, int>{
      for (final id in fieldMap.keys) id: 0,
    };
    for (final log in logs) {
      final activeIds = log.activeFieldIds.toSet();
      for (final id in fieldMap.keys) {
        if (!activeIds.contains(id)) {
          inactiveLoggedDays[id] = (inactiveLoggedDays[id] ?? 0) + 1;
        }
      }
      for (final id in activeIds) {
        final f = fieldMap[id];
        if (f == null) continue;
        if (f.type == amal_const.AmalType.numeric) {
          final value = getNumericValue(log.toggles[f.id], f.maxValue);
          numericSums[f.id] = (numericSums[f.id] ?? 0) + value;
          if (value > 0) done[f.id] = (done[f.id] ?? 0) + 1;
        } else {
          if (log.toggles[f.id] == true) {
            done[f.id] = (done[f.id] ?? 0) + 1;
          }
        }
      }
    }

    final stats = fieldMap.values
        .map((f) {
          final fieldEligible =
              (eligible - (inactiveLoggedDays[f.id] ?? 0)).clamp(0, eligible);
          final count = done[f.id] ?? 0;
          final rate = fieldEligible == 0
              ? 0.0
              : f.type == amal_const.AmalType.numeric
                  ? (numericSums[f.id] ?? 0) / (fieldEligible * f.maxValue)
                  : count / fieldEligible;
          return ReportAmalStat(
            id: f.id,
            label: f.getLabel(locale),
            doneCount: count,
            eligibleDays: fieldEligible,
            rate: rate,
          );
        })
        .toList()
      ..sort((a, b) => b.rate.compareTo(a.rate));
    return stats;
  }

  static int _bestStreak(List<String> loggedKeysSorted) {
    if (loggedKeysSorted.isEmpty) return 0;
    final sorted = List<String>.from(loggedKeysSorted)..sort();
    var best = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (IslamicDateService.areConsecutiveIslamicDays(
        sorted[i - 1],
        sorted[i],
      )) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  static List<ReportBarPoint> _buildBars({
    required List<String> dayKeys,
    required Map<String, AmalLogModel> byDate,
    required String todayStr,
    required String accountCreatedHijri,
    required String locale,
  }) {
    final usable = dayKeys.where((k) {
      if (k.compareTo(accountCreatedHijri) < 0) return false;
      if (k.compareTo(todayStr) > 0) return false;
      return true;
    }).toList();

    if (usable.isEmpty) return const [];

    if (usable.length <= bucketThresholdDays) {
      return usable.map((key) {
        final log = byDate[key];
        return ReportBarPoint(
          label: _shortWeekdayLabel(key, locale),
          score: log?.score ?? 0,
          hasLog: log != null,
          maxScore: log?.maxScore ?? 100,
          specialTimeApplied: log?.specialTimeApplied ?? false,
          hijriDate: key,
        );
      }).toList();
    }

    // Aggregate into week-sized buckets (max ~13 for 90 days).
    const bucketSize = 7;
    final bars = <ReportBarPoint>[];
    for (var i = 0; i < usable.length; i += bucketSize) {
      final chunk = usable.sublist(
        i,
        (i + bucketSize).clamp(0, usable.length),
      );
      final scored = chunk
          .map((k) => byDate[k])
          .whereType<AmalLogModel>()
          .where((l) => l.score > 0)
          .toList();
      final avg = scored.isEmpty
          ? 0
          : (scored.map((l) => l.score).reduce((a, b) => a + b) / scored.length)
                .round();
      final avgMax = scored.isEmpty
          ? 100
          : (scored.map((l) => l.maxScore).reduce((a, b) => a + b) / scored.length)
                .round();
      final anySpecialTime = scored.any((l) => l.specialTimeApplied);
      final weekIndex = (i ~/ bucketSize) + 1;
      bars.add(
        ReportBarPoint(
          label: locale == 'bn' ? 'স$weekIndex' : 'W$weekIndex',
          score: avg,
          hasLog: scored.isNotEmpty,
          maxScore: avgMax,
          specialTimeApplied: anySpecialTime,
          hijriDate: chunk.first,
        ),
      );
    }
    return bars;
  }

  static String? _pickHadith(List<String> hadiths, String periodKey) {
    if (hadiths.isEmpty) return null;
    var hash = 0;
    for (final unit in periodKey.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hadiths[hash % hadiths.length];
  }

  static String _weekdayForStorage(String hijriYyyyMmDd, String locale) {
    final en = IslamicDateService.weekdayEnglishForStorage(hijriYyyyMmDd);
    if (locale != 'bn' || en.isEmpty) return en;
    const map = {
      'Monday': 'সোমবার',
      'Tuesday': 'মঙ্গলবার',
      'Wednesday': 'বুধবার',
      'Thursday': 'বৃহস্পতিবার',
      'Friday': 'শুক্রবার',
      'Saturday': 'শনিবার',
      'Sunday': 'রবিবার',
    };
    return map[en] ?? en;
  }

  static String _shortWeekdayLabel(String hijriYyyyMmDd, String locale) {
    final en = IslamicDateService.weekdayEnglishForStorage(hijriYyyyMmDd);
    if (en.isEmpty) return hijriYyyyMmDd.split('-').last;
    if (locale == 'bn') {
      const map = {
        'Monday': 'সোম',
        'Tuesday': 'মঙ্গল',
        'Wednesday': 'বুধ',
        'Thursday': 'বৃহঃ',
        'Friday': 'শুক্র',
        'Saturday': 'শনি',
        'Sunday': 'রবি',
      };
      return map[en] ?? en;
    }
    return en.substring(0, en.length >= 3 ? 3 : en.length);
  }
}
