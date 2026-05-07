import 'dart:developer' as developer;

import 'package:hijri/hijri_calendar.dart';

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

String weekKeyFromDate(DateTime date) {
  final midnight = DateTime(date.year, date.month, date.day);
  final weekday = midnight.weekday; // Monday = 1
  final monday = midnight.subtract(Duration(days: weekday - 1));
  return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
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
  developer.log(
    '[StreakHelper] computeStreakResult(lastLogDate=$lastLogDate, todayHijri=$todayHijri, '
    'currentStreak=$currentStreak, bestStreak=$bestStreak, streakFreezeUsed=$streakFreezeUsed)',
    name: 'StreakHelper',
  );

  if (lastLogDate.isEmpty) {
    const newStreak = 1;
    developer.log(
      '[StreakHelper] No lastLogDate; starting new streak at $newStreak (best=${newStreak > bestStreak ? newStreak : bestStreak})',
      name: 'StreakHelper',
    );
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
    developer.log(
      '[StreakHelper] Failed to parse Hijri dates (lastLogDate=$lastLogDate, todayHijri=$todayHijri); '
      'resetting streak to 1 and keeping bestStreak=$bestStreak',
      name: 'StreakHelper',
    );
    return StreakResult(
      action: StreakAction.reset,
      newCurrentStreak: 1,
      newBestStreak: bestStreak,
    );
  }

  final diffDays = _calendarDaysBetween(lastG, todayG);
  developer.log(
    '[StreakHelper] diffDays between lastG=$lastG and todayG=$todayG is $diffDays',
    name: 'StreakHelper',
  );

  if (diffDays <= 0) {
    final keep = currentStreak > 0 ? currentStreak : 1;
    developer.log(
      '[StreakHelper] diffDays<=0; keeping streak at $keep (best=${keep > bestStreak ? keep : bestStreak})',
      name: 'StreakHelper',
    );
    return StreakResult(
      action: StreakAction.increment,
      newCurrentStreak: keep,
      newBestStreak: keep > bestStreak ? keep : bestStreak,
    );
  }

  if (diffDays == 1) {
    // If Firestore hasn't yet updated `currentStreak` for the previous day,
    // we might see `currentStreak == 0` even though [lastLogDate] is a valid
    // logged day. In that case, treat the baseline as 1 before incrementing.
    final baselineCurrent = currentStreak <= 0 ? 1 : currentStreak;
    final newCurrent = baselineCurrent + 1;
    final newBest = newCurrent > bestStreak ? newCurrent : bestStreak;
    developer.log(
      '[StreakHelper] Consecutive day; incrementing streak from baseline=$baselineCurrent '
      'to $newCurrent (best=$newBest)',
      name: 'StreakHelper',
    );
    return StreakResult(
      action: StreakAction.increment,
      newCurrentStreak: newCurrent,
      newBestStreak: newBest,
    );
  }

  if (diffDays == 2 && !streakFreezeUsed) {
    developer.log(
      '[StreakHelper] Missed exactly one day and freeze not used; showing freeze modal, '
      'keeping currentStreak=$currentStreak, bestStreak=$bestStreak',
      name: 'StreakHelper',
    );
    return StreakResult(
      action: StreakAction.showFreeze,
      newCurrentStreak: currentStreak,
      newBestStreak: bestStreak,
    );
  }

  developer.log(
    '[StreakHelper] Gap too large or freeze already used; resetting streak to 1 (bestStreak=$bestStreak)',
    name: 'StreakHelper',
  );
  return StreakResult(
    action: StreakAction.reset,
    newCurrentStreak: 1,
    newBestStreak: bestStreak,
  );
}

/// Keeps Home and History streak cards in sync when today's submit is done
/// but Firestore user streak fields have not refreshed yet.
DisplayStreakValues resolveDisplayedStreakValues({
  required int currentStreak,
  required int bestStreak,
  required bool hasSubmittedToday,
}) {
  final effectiveCurrent = (currentStreak == 0 && hasSubmittedToday)
      ? 1
      : currentStreak;
  final effectiveBest = bestStreak < effectiveCurrent
      ? effectiveCurrent
      : bestStreak;
  return DisplayStreakValues(
    currentStreak: effectiveCurrent,
    bestStreak: effectiveBest,
  );
}
