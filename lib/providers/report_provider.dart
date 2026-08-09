import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../core/services/analytics_service.dart';
import '../core/services/hadith_asset_service.dart';
import '../core/services/islamic_date_service.dart';
import '../core/utils/report_calculator.dart';
import '../core/utils/streak_helper.dart';
import '../models/amal_log_model.dart';
import 'amal_fields_provider.dart';
import 'auth_provider.dart';
import 'history_provider.dart';
import 'locale_provider.dart';

enum ReportPeriodType { weekly, monthly, custom }

class ReportPeriodKey {
  const ReportPeriodKey({
    required this.uid,
    required this.type,
    required this.startHijri,
    required this.endHijri,
  });

  final String uid;
  final ReportPeriodType type;
  final String startHijri;
  final String endHijri;

  String get periodKey => '${type.name}|$startHijri|$endHijri';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportPeriodKey &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          type == other.type &&
          startHijri == other.startHijri &&
          endHijri == other.endHijri;

  @override
  int get hashCode => Object.hash(uid, type, startHijri, endHijri);
}

/// Current rolling 7-day Hijri week (matches weekly leaderboard window).
({String start, String end}) currentWeeklyRange() {
  final end = IslamicDateService.getCurrentIslamicDateStringSafe();
  final start = IslamicDateService.shiftStorageByDays(end, -6);
  return (start: start, end: end);
}

/// Hijri month range; clamps end to today when viewing the current month.
({String start, String end}) monthlyRange(int hijriYear, int hijriMonth) {
  final cal = HijriCalendar();
  final daysInMonth = cal.getDaysInMonth(hijriYear, hijriMonth);
  final mm = hijriMonth.toString().padLeft(2, '0');
  final start = '$hijriYear-$mm-01';
  final today = IslamicDateService.getCurrentIslamicDateStringSafe();
  final monthEnd = '$hijriYear-$mm-${daysInMonth.toString().padLeft(2, '0')}';
  final end =
      today.compareTo(monthEnd) < 0 && today.startsWith('$hijriYear-$mm')
      ? today
      : monthEnd;
  return (start: start, end: end);
}

({String start, String end}) previousRangeFor(
  ReportPeriodType type,
  String startHijri,
  String endHijri,
) {
  final days = IslamicDateService.daysBetween(startHijri, endHijri) + 1;
  switch (type) {
    case ReportPeriodType.weekly:
      final prevEnd = IslamicDateService.shiftStorageByDays(startHijri, -1);
      final prevStart = IslamicDateService.shiftStorageByDays(prevEnd, -6);
      return (start: prevStart, end: prevEnd);
    case ReportPeriodType.monthly:
      final parts = startHijri.split('-');
      if (parts.length != 3) {
        final prevEnd = IslamicDateService.shiftStorageByDays(startHijri, -1);
        final prevStart = IslamicDateService.shiftStorageByDays(
          prevEnd,
          -(days - 1),
        );
        return (start: prevStart, end: prevEnd);
      }
      var y = int.tryParse(parts[0]) ?? 1440;
      var m = int.tryParse(parts[1]) ?? 1;
      if (m > 1) {
        m--;
      } else {
        y--;
        m = 12;
      }
      return monthlyRange(y, m);
    case ReportPeriodType.custom:
      final prevEnd = IslamicDateService.shiftStorageByDays(startHijri, -1);
      final prevStart = IslamicDateService.shiftStorageByDays(
        prevEnd,
        -(days - 1),
      );
      return (start: prevStart, end: prevEnd);
  }
}

bool isLiveCurrentWeek(String startHijri, String endHijri) {
  final live = currentWeeklyRange();
  return startHijri == live.start && endHijri == live.end;
}

bool isLiveCurrentMonth(String startHijri, String endHijri) {
  final ym = IslamicDateService.currentHijriYearMonth();
  final live = monthlyRange(ym.year, ym.month);
  return startHijri == live.start && endHijri == live.end;
}

final reportSummaryProvider =
    FutureProvider.autoDispose.family<ReportSummary, ReportPeriodKey>((
      ref,
      key,
    ) async {
      ref.watch(amalLogRefreshProvider);
      final fs = ref.read(firestoreServiceProvider);
      final fields = ref.watch(amalFieldsListProvider);
      final todayStr = IslamicDateService.getCurrentIslamicDateStringSafe();
      final user = await ref.watch(currentUserProvider.future);
      if (user == null) {
        throw StateError('User profile unavailable');
      }
      final accountCreatedHijri =
          IslamicDateService.hijriStorageForAccountCreated(user.createdAt);
      final locale = ref.watch(localeProvider).languageCode;

      final prev = previousRangeFor(key.type, key.startHijri, key.endHijri);
      final needRank =
          (key.type == ReportPeriodType.weekly &&
              isLiveCurrentWeek(key.startHijri, key.endHijri)) ||
          (key.type == ReportPeriodType.monthly &&
              isLiveCurrentMonth(key.startHijri, key.endHijri));

      try {
        final results = await Future.wait<Object?>([
          fs.getLogsInRange(key.uid, key.startHijri, key.endHijri),
          fs.getLogsInRange(key.uid, prev.start, prev.end),
          if (needRank && key.type == ReportPeriodType.weekly)
            fs.weeklyLeaderboard()
          else if (needRank && key.type == ReportPeriodType.monthly)
            fs.monthlyLeaderboard()
          else
            Future.value(const <Map<String, dynamic>>[]),
          HadithAssetService.loadHadithTexts(),
        ]);

        final logs = results[0]! as List<AmalLogModel>;
        final previousLogs = results[1]! as List<AmalLogModel>;
        final leaderboardRows = results[2]! as List<Map<String, dynamic>>;
        final hadiths = results[3]! as List<String>;

        ReportRankInfo? rankInfo;
        if (needRank && leaderboardRows.isNotEmpty) {
          final users = await fs.usersByIds(
            leaderboardRows.map((r) => (r['uid'] as String?) ?? ''),
          );
          final visible = <Map<String, dynamic>>[];
          for (final row in leaderboardRows) {
            final uid = (row['uid'] as String?) ?? '';
            if (uid.isEmpty) continue;
            final show = users[uid]?.showOnLeaderboard ?? true;
            if (!show) continue;
            visible.add(row);
          }
          final index = visible.indexWhere((r) => r['uid'] == key.uid);
          if (index >= 0) {
            rankInfo = ReportRankInfo(
              rank: index + 1,
              totalParticipants: visible.length,
              topScore: (visible.first['score'] as int?) ?? 0,
              userScore: (visible[index]['score'] as int?) ?? 0,
            );
          }
        }

        final liveStreak = ref.watch(liveStreakProvider).value ?? user.currentStreak;
        final displayStreak = DisplayStreakValues(
          currentStreak: liveStreak,
          bestStreak: user.bestStreak < liveStreak ? liveStreak : user.bestStreak,
        );

        return ReportCalculator.compute(
          logs: logs,
          fields: fields,
          startHijri: key.startHijri,
          endHijri: key.endHijri,
          todayStr: todayStr,
          accountCreatedHijri: accountCreatedHijri,
          locale: locale,
          previousPeriodLogs: previousLogs,
          rankInfo: rankInfo,
          liveCurrentStreak: displayStreak.currentStreak,
          hadithTexts: hadiths,
          periodKey: key.periodKey,
        );
      } catch (e, st) {
        AnalyticsService.instance.recordError(
          e,
          st,
          reason: 'Report load failed',
        );
        rethrow;
      }
    });
