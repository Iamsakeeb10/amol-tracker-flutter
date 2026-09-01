import 'package:hijri/hijri_calendar.dart';

import '../services/islamic_date_service.dart';
import '../../models/amal_log_model.dart';

/// What to do after submitting today's log, based on [lastLogDate] vs [todayHijri].
enum StreakAction {
  /// User logged the previous Hijri day — increment streak (or start at 1).
  increment,

  /// Missed exactly one Hijri day and freeze is available — show S-16 modal.
  showFreeze,

  /// Gap > 1 day, or gap == 2 but freeze already used — streak becomes 1.
  reset,
}

/// Result of [computeStreakResult] for UI and Firestore updates.
class StreakResult {
  const StreakResult({
    required this.action,
    required this.newCurrentStreak,
    required this.newBestStreak,
  });

  final StreakAction action;
  final int newCurrentStreak;
  final int newBestStreak;
}

/// UI-facing streak values resolved consistently across screens.
class DisplayStreakValues {
  const DisplayStreakValues({
    required this.currentStreak,
    required this.bestStreak,
  });

  final int currentStreak;
  final int bestStreak;
}

/// Parses `YYYY-MM-DD` Hijri storage string to a calendar [DateTime] (local date).
DateTime hijriStorageStringToGregorian(String hijriYyyyMmDd) {
  final parts = hijriYyyyMmDd.split('-');
  if (parts.length != 3) {
    throw FormatException('Invalid Hijri date: $hijriYyyyMmDd');
  }
  final y = int.parse(parts[0], radix: 10);
  final m = int.parse(parts[1], radix: 10);
  final d = int.parse(parts[2], radix: 10);
  final cal = HijriCalendar();
  return cal.hijriToGregorian(y, m, d);
}

int _calendarDaysBetween(DateTime a, DateTime b) {
  final aa = DateTime(a.year, a.month, a.day);
  final bb = DateTime(b.year, b.month, b.day);
  return bb.difference(aa).inDays;
}

/// Returns true if [log] was backfilled — submitted on a different Hijri day
/// than the log's own [hijriDate]. Backfilled logs should not count towards
/// streak computation.
///
/// Uses standard date conversion so a submission after midnight
/// (which counts as the next day) is not falsely marked backfilled.
bool isBackfilledLog(AmalLogModel log) {
  try {
    final submittedBd = IslamicDateService.bangladeshDateTimeFrom(
      log.submittedAt,
    );
    final submittedHijri =
        IslamicDateService.islamicDateStringForBangladeshMoment(submittedBd);
    return submittedHijri != log.hijriDate;
  } catch (_) {
    return false;
  }
}

String weekKeyFromDate(DateTime date) {
  final midnight = DateTime(date.year, date.month, date.day);
  final weekday = midnight.weekday; // Monday = 1
  final monday = midnight.subtract(Duration(days: weekday - 1));
  return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
}

/// Computes streak from a set of logged Hijri dates by counting consecutive
/// completed days backwards from [todayHijri].
///
/// This is the source-of-truth for streak display, computed from actual logs
/// rather than the potentially stale Firestore `currentStreak` field.
///
/// If today is not in [loggedDates], walks backwards from yesterday so the
/// streak still reflects the most recent consecutive chain.
int computeStreakFromLogs({
  required Set<String> loggedDates,
  required String todayHijri,
  Set<String> frozenDates = const {},
}) {
  if (loggedDates.isEmpty && frozenDates.isEmpty) return 0;

  // Combine actual logs and frozen dates for consecutive-day checking.
  final coveredDates = {...loggedDates, ...frozenDates};

  var streak = 0;
  var candidate = todayHijri;
  while (coveredDates.contains(candidate)) {
    streak++;
    candidate = IslamicDateService.shiftStorageByDays(candidate, -1);
  }

  if (streak == 0) {
    candidate = IslamicDateService.shiftStorageByDays(todayHijri, -1);
    while (coveredDates.contains(candidate)) {
      streak++;
      candidate = IslamicDateService.shiftStorageByDays(candidate, -1);
    }
  }

  return streak;
}

/// Computes streak transition when submitting a log on [todayHijri].
///
/// [lastLogDate] is the user's previous `lastLogDate` from Firestore (before this submit).
StreakResult computeStreakResult({
  required String lastLogDate,
  required String todayHijri,
  required int currentStreak,
  required int bestStreak,
  required bool streakFreezeUsed,
}) {
  if (lastLogDate.isEmpty) {
    const newStreak = 1;
    return StreakResult(
      action: StreakAction.increment,
      newCurrentStreak: newStreak,
      newBestStreak: newStreak > bestStreak ? newStreak : bestStreak,
    );
  }

  DateTime lastG;
  DateTime todayG;
  try {
    lastG = hijriStorageStringToGregorian(lastLogDate);
    todayG = hijriStorageStringToGregorian(todayHijri);
  } catch (_) {
    return StreakResult(
      action: StreakAction.reset,
      newCurrentStreak: 1,
      newBestStreak: bestStreak,
    );
  }

  final diffDays = _calendarDaysBetween(lastG, todayG);

  if (diffDays <= 0) {
    final keep = currentStreak > 0 ? currentStreak : 1;
    return StreakResult(
      action: StreakAction.increment,
      newCurrentStreak: keep,
      newBestStreak: keep > bestStreak ? keep : bestStreak,
    );
  }

  if (diffDays == 1) {
    final baselineCurrent = currentStreak <= 0 ? 1 : currentStreak;
    final newCurrent = baselineCurrent + 1;
    final newBest = newCurrent > bestStreak ? newCurrent : bestStreak;
    return StreakResult(
      action: StreakAction.increment,
      newCurrentStreak: newCurrent,
      newBestStreak: newBest,
    );
  }

  if (diffDays == 2 && !streakFreezeUsed) {
    final preserved = currentStreak > 0 ? currentStreak : 1;
    return StreakResult(
      action: StreakAction.showFreeze,
      newCurrentStreak: preserved,
      newBestStreak: bestStreak,
    );
  }

  return StreakResult(
    action: StreakAction.reset,
    newCurrentStreak: 1,
    newBestStreak: bestStreak,
  );
}

/// Returns the streak value after applying a freeze to [currentStreak].
int streakAfterFreeze(int currentStreak) {
  final baseline = currentStreak <= 0 ? 1 : currentStreak;
  return baseline + 2; // +1 for frozen day, +1 for today
}

/// Keeps Home and History streak cards in sync when today's submit is done
/// but Firestore user streak fields have not refreshed yet.
///
/// Uses [lastLogDate] to cross-check: if there's a gap between [lastLogDate]
/// and today, the Firestore `currentStreak` is stale and we cap it at 1.
DisplayStreakValues resolveDisplayedStreakValues({
  required int currentStreak,
  required int bestStreak,
  required bool hasSubmittedToday,
  String? lastLogDate,
}) {
  int effectiveCurrent;

  if (hasSubmittedToday && lastLogDate != null && lastLogDate.isNotEmpty) {
    // Cross-check: verify the Firestore streak against lastLogDate.
    try {
      final lastG = hijriStorageStringToGregorian(lastLogDate);
      final todayG = hijriStorageStringToGregorian(
        IslamicDateService.getCurrentIslamicDateStringSafe(),
      );
      final diffDays = _calendarDaysBetween(lastG, todayG);

      if (diffDays <= 0) {
        // Submitted today — streak is at least 1.
        effectiveCurrent = currentStreak <= 0 ? 1 : currentStreak;
      } else if (diffDays == 1) {
        // Submitted yesterday — Firestore may not have incremented yet.
        // If currentStreak is 0 or 1, treat as 2 (yesterday + today).
        effectiveCurrent = currentStreak <= 1 ? 2 : currentStreak;
      } else {
        // Gap exists — streak was broken. After today's submit it's 1.
        effectiveCurrent = 1;
      }
    } catch (_) {
      effectiveCurrent = (currentStreak == 0 && hasSubmittedToday)
          ? 1
          : currentStreak;
    }
  } else if (hasSubmittedToday) {
    effectiveCurrent = currentStreak <= 0 ? 1 : currentStreak;
  } else {
    effectiveCurrent = currentStreak;
  }

  final effectiveBest = bestStreak < effectiveCurrent
      ? effectiveCurrent
      : bestStreak;
  return DisplayStreakValues(
    currentStreak: effectiveCurrent,
    bestStreak: effectiveBest,
  );
}
