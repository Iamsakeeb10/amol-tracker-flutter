import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/islamic_date_service.dart';
import '../core/utils/personal_amol_schedule.dart';
import '../core/utils/report_calculator.dart';
import '../models/personal_amol_model.dart';
import 'amal_provider.dart';
import 'personal_amol_provider.dart';

/// Key for a personal-amol report period (mirrors [ReportPeriodKey] range).
class PersonalAmolReportKey {
  const PersonalAmolReportKey({
    required this.uid,
    required this.startHijri,
    required this.endHijri,
  });

  final String uid;
  final String startHijri;
  final String endHijri;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalAmolReportKey &&
          uid == other.uid &&
          startHijri == other.startHijri &&
          endHijri == other.endHijri;

  @override
  int get hashCode => Object.hash(uid, startHijri, endHijri);
}

/// Per-amol completion stats for a report period.
class PersonalAmolReportStat {
  const PersonalAmolReportStat({
    required this.amolId,
    required this.name,
    required this.icon,
    required this.type,
    required this.target,
    required this.eligibleDays,
    required this.completedDays,
    required this.totalCompletions,
    required this.rate,
    required this.isActive,
  });

  final String amolId;
  final String name;
  final String icon;
  final PersonalAmolType type;
  final int target;

  /// Days the amol was scheduled in the period (after creation; today only
  /// when community amal is submitted).
  final int eligibleDays;

  /// Days where the amol was fully done (toggle on, or count ≥ target).
  final int completedDays;

  /// Sum of all completion docs in the period (useful for count-type).
  final int totalCompletions;

  /// [completedDays] / [eligibleDays], or 0 when no eligible days.
  final double rate;

  final bool isActive;
}

/// Pure computation of personal-amol report stats for a Hijri range.
///
/// Business rules:
/// - Soft-deleted amols are included when they have completions in-range
///   (or are still active).
/// - Eligible days start at the amol's Hijri creation day, not period start.
/// - Weekday amols only count scheduled weekdays.
/// - Today is excluded until [includeToday] is true (community amal submitted),
///   matching community report averages.
/// - Count-type days count as completed only when completions ≥ target.
List<PersonalAmolReportStat> computePersonalAmolReportStats({
  required List<PersonalAmolModel> amols,
  required List<PersonalAmolCompletion> completions,
  required String startHijri,
  required String endHijri,
  required String todayHijri,
  bool includeToday = false,
}) {
  if (amols.isEmpty) return const [];

  final perDateAmol = <String, Map<String, int>>{};
  final totalByAmol = <String, int>{};
  for (final c in completions) {
    if (c.hijriDate.compareTo(startHijri) < 0) continue;
    if (c.hijriDate.compareTo(endHijri) > 0) continue;
    final perAmol =
        perDateAmol.putIfAbsent(c.hijriDate, () => <String, int>{});
    perAmol[c.amolId] = (perAmol[c.amolId] ?? 0) + 1;
    totalByAmol[c.amolId] = (totalByAmol[c.amolId] ?? 0) + 1;
  }

  // Cap eligible end at yesterday until today's community amal is submitted;
  // then include today so incomplete personal amol pulls the rate down.
  final capDay = includeToday
      ? todayHijri
      : IslamicDateService.shiftStorageByDays(todayHijri, -1);
  final effectiveEnd =
      endHijri.compareTo(capDay) <= 0 ? endHijri : capDay;
  if (effectiveEnd.compareTo(startHijri) < 0) {
    return const [];
  }

  final dayKeys = _enumerateDays(startHijri, effectiveEnd);
  final stats = <PersonalAmolReportStat>[];

  for (final amol in amols) {
    final hasCompletions = (totalByAmol[amol.id] ?? 0) > 0;
    if (!amol.isActive && !hasCompletions) continue;

    var eligible = 0;
    var completed = 0;
    final createdHijri = IslamicDateService.hijriStorageForAccountCreated(
      amol.createdAt,
    );
    for (final day in dayKeys) {
      // Use BD Hijri storage (not device-local) so eligibility matches
      // community report account-creation floors.
      if (day.compareTo(createdHijri) < 0) continue;
      if (!personalAmolScheduledOn(amol, day)) continue;
      eligible++;
      final count = perDateAmol[day]?[amol.id] ?? 0;
      final target = amol.type == PersonalAmolType.count ? amol.target : 1;
      if (count >= target) completed++;
    }

    // Soft-deleted with zero eligible scheduled days but lingering completions
    // on unscheduled / pre-creation days: still show a row with 0 rate.
    if (eligible == 0 && !hasCompletions) continue;

    stats.add(
      PersonalAmolReportStat(
        amolId: amol.id,
        name: amol.name,
        icon: amol.icon,
        type: amol.type,
        target: amol.target,
        eligibleDays: eligible,
        completedDays: completed,
        totalCompletions: totalByAmol[amol.id] ?? 0,
        rate: eligible == 0 ? 0.0 : completed / eligible,
        isActive: amol.isActive,
      ),
    );
  }

  stats.sort((a, b) => b.rate.compareTo(a.rate));
  return stats;
}

List<String> _enumerateDays(String start, String end) {
  if (start.isEmpty || end.isEmpty) return const [];
  final from = start.compareTo(end) <= 0 ? start : end;
  final to = start.compareTo(end) <= 0 ? end : start;
  final out = <String>[];
  var cursor = from;
  for (var i = 0; i < ReportCalculator.maxCustomDays + 7; i++) {
    out.add(cursor);
    if (cursor == to) break;
    final next = IslamicDateService.shiftStorageByDays(cursor, 1);
    if (next == cursor || next.compareTo(cursor) <= 0) break;
    cursor = next;
  }
  return out;
}

/// Personal-amol breakdown for the selected report period.
final personalAmolReportProvider = FutureProvider.autoDispose
    .family<List<PersonalAmolReportStat>, PersonalAmolReportKey>((
  ref,
  key,
) async {
  ref.watch(personalAmolRefreshProvider);
  // Recompute when definitions change (targets / weekdays / soft-delete).
  final amols = await ref.watch(allPersonalAmolProvider(key.uid).future);
  if (amols.isEmpty) return const [];

  // Match community reports: include today only after community amal submit.
  final includeToday = ref.watch(amalProvider(key.uid)).isSubmitted;

  final repo = ref.read(personalAmolRepositoryProvider);
  final today = IslamicDateService.getCurrentIslamicDateStringSafe();
  final completions = await repo.getCompletionsInRange(
    key.uid,
    key.startHijri,
    key.endHijri,
  );

  return computePersonalAmolReportStats(
    amols: amols,
    completions: completions,
    startHijri: key.startHijri,
    endHijri: key.endHijri,
    todayHijri: today,
    includeToday: includeToday,
  );
});
