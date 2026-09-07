import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:riverpod/legacy.dart';

import '../core/constants/app_constants.dart';
import '../core/services/islamic_date_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/personal_amol_repository.dart';
import '../core/utils/personal_amol_schedule.dart';
import '../core/utils/streak_helper.dart';
import '../models/personal_amol_model.dart';
import '../models/personal_amol_streak_model.dart';
import 'date_provider.dart';

final personalAmolRepositoryProvider = Provider<PersonalAmolRepository>(
  (ref) => PersonalAmolRepository(),
);

class PersonalAmolRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final personalAmolRefreshProvider =
    NotifierProvider<PersonalAmolRefreshNotifier, int>(
      PersonalAmolRefreshNotifier.new,
    );

/// Active (non-deleted) personal amol definitions for a user.
final activePersonalAmolProvider =
    StreamProvider.autoDispose.family<List<PersonalAmolModel>, String>((
  ref,
  uid,
) {
  return ref.watch(personalAmolRepositoryProvider).watchActiveAmol(uid);
});

/// All personal amol definitions (including soft-deleted) for a user. The
/// history calendar uses this so past completions of deleted amols still fill.
final allPersonalAmolProvider =
    StreamProvider.autoDispose.family<List<PersonalAmolModel>, String>((
  ref,
  uid,
) {
  return ref.watch(personalAmolRepositoryProvider).watchAllAmol(uid);
});

/// Completions for today. Auto-reloads when the Hijri date rolls over or after
/// a toggle.
final personalAmolCompletionsForTodayProvider =
    StreamProvider.autoDispose.family<List<PersonalAmolCompletion>, String>((
  ref,
  uid,
) async* {
  ref.watch(currentHijriDateProvider);
  ref.watch(personalAmolRefreshProvider);
  yield await ref
      .read(personalAmolRepositoryProvider)
      .getCompletionsForDate(
        uid,
        IslamicDateService.getCurrentIslamicDateStringSafe(),
      );
});

class PersonalAmolDateKey {
  const PersonalAmolDateKey({required this.uid, required this.hijriDate});

  final String uid;
  final String hijriDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalAmolDateKey &&
          uid == other.uid &&
          hijriDate == other.hijriDate;

  @override
  int get hashCode => Object.hash(uid, hijriDate);
}

/// Completions for a specific Hijri date (day-detail screen).
final personalAmolCompletionsForDateProvider = FutureProvider.autoDispose
    .family<List<PersonalAmolCompletion>, PersonalAmolDateKey>((ref, key) {
  return ref
      .read(personalAmolRepositoryProvider)
      .getCompletionsForDate(key.uid, key.hijriDate);
});

class PersonalAmolMonthKey {
  const PersonalAmolMonthKey({
    required this.uid,
    required this.hijriYear,
    required this.hijriMonth,
  });

  final String uid;
  final int hijriYear;
  final int hijriMonth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalAmolMonthKey &&
          uid == other.uid &&
          hijriYear == other.hijriYear &&
          hijriMonth == other.hijriMonth;

  @override
  int get hashCode => Object.hash(uid, hijriYear, hijriMonth);
}

/// Counts fully-done personal amols per Hijri date, including soft-deleted
/// amols so their past completions keep counting. A day is skipped for an amol
/// when it isn't scheduled on that weekday. A toggle amol is done with one
/// completion; a count amol only when its completions reach [target].
/// Pure & testable; used by the month summary provider.
Map<String, int> fullyDonePersonalAmolByDay(
  List<PersonalAmolCompletion> completions,
  List<PersonalAmolModel> amols,
) {
  final perDateAmol = <String, Map<String, int>>{};
  for (final c in completions) {
    final perAmol = perDateAmol.putIfAbsent(c.hijriDate, () => <String, int>{});
    perAmol[c.amolId] = (perAmol[c.amolId] ?? 0) + 1;
  }
  final byDay = <String, int>{};
  for (final entry in perDateAmol.entries) {
    var fullyDone = 0;
    for (final amol in amols) {
      if (!personalAmolScheduledOn(amol, entry.key)) continue;
      final count = entry.value[amol.id] ?? 0;
      final target = amol.type == PersonalAmolType.count ? amol.target : 1;
      if (count >= target) fullyDone++;
    }
    if (fullyDone > 0) byDay[entry.key] = fullyDone;
  }
  return byDay;
}

/// Fully-done personal-amol count per Hijri date for a month (history calendar
/// merge and home progress). Includes soft-deleted amols (so their past
/// completions keep counting) and only counts an amol on days it is scheduled.
/// [scheduledByDay] maps each day to its number of scheduled amols. This is
/// display-only and must not feed any leaderboard or comparative computation.
final personalAmolMonthCompletionSummaryProvider =
    FutureProvider.autoDispose.family<
      ({Map<String, int> doneByDay, Map<String, int> scheduledByDay}),
      PersonalAmolMonthKey
    >((ref, key) async {
      ref.watch(personalAmolRefreshProvider);
      final repo = ref.read(personalAmolRepositoryProvider);
      // Recompute when definitions change (targets/types/weekdays can mutate).
      final amols = ref.watch(allPersonalAmolProvider(key.uid)).value ??
          const <PersonalAmolModel>[];
      final first = IslamicDateService.storageFromParts(
        key.hijriYear,
        key.hijriMonth,
        1,
      );
      final daysInMonth = HijriCalendar().getDaysInMonth(
        key.hijriYear,
        key.hijriMonth,
      );
      final last = IslamicDateService.storageFromParts(
        key.hijriYear,
        key.hijriMonth,
        daysInMonth,
      );
      // Count completions per (date, amol) then reduce to fully-done amols.
      final completions = await repo.getCompletionsInRange(
        key.uid,
        first,
        last,
      );
      return (
        doneByDay: fullyDonePersonalAmolByDay(completions, amols),
        scheduledByDay: scheduledPersonalAmolByDay(
          amols: amols,
          firstHijri: first,
          lastHijri: last,
        ),
      );
    });

class PersonalAmolStreakKey {
  const PersonalAmolStreakKey({required this.uid, required this.amolId});

  final String uid;
  final String amolId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalAmolStreakKey &&
          uid == other.uid &&
          amolId == other.amolId;

  @override
  int get hashCode => Object.hash(uid, amolId);
}

/// Per-amol personal streak, watched from `personal_amol_streaks/{amolId}`.
final personalAmolStreakProvider =
    StreamProvider.autoDispose.family<PersonalStreakResult?, PersonalAmolStreakKey>((
  ref,
  key,
) {
  return ref
      .read(personalAmolRepositoryProvider)
      .watchStreak(key.uid, key.amolId);
});

final personalAmolNotifierProvider =
    StateNotifierProvider.family<PersonalAmolNotifier, Map<String, PersonalAmolModel>, String>(
  (ref, uid) => PersonalAmolNotifier(ref, uid),
);

/// Owns all personal-amol mutations for a single user. Streak computation
/// reuses `computeStreakFromLogs` (same Hijri/Maghrib boundary as community
/// amol) but always writes to the separate `personal_amol_streaks` documents.
class PersonalAmolNotifier extends StateNotifier<Map<String, PersonalAmolModel>> {
  PersonalAmolNotifier(this._ref, this._uid)
      : super(const <String, PersonalAmolModel>{}) {
    _subscription = _repo.watchActiveAmol(_uid).listen(
      (list) => state = {for (final a in list) a.id: a},
      onError: (_) {},
    );
  }

  final Ref _ref;
  final String _uid;
  StreamSubscription<List<PersonalAmolModel>>? _subscription;

  PersonalAmolRepository get _repo =>
      _ref.read(personalAmolRepositoryProvider);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  bool get atCap => state.length >= AppConstants.kMaxFreePersonalAmol;

  Future<void> createAmol(PersonalAmolModel amol) async {
    if (atCap) {
      throw StateError('max personal amol reached');
    }
    await _repo.createAmol(_uid, amol);
    final slot = _slotFor(amol.id);
    await _scheduleReminderFor(amol, slot: slot);
  }

  Future<void> updateAmol(PersonalAmolModel amol) async {
    await _repo.updateAmol(_uid, amol);
    final slot = _slotFor(amol.id);
    await _scheduleReminderFor(amol, slot: slot);
  }

  Future<void> softDeleteAmol(String amolId) async {
    final slot = _slotFor(amolId);
    await _repo.softDeleteAmol(_uid, amolId);
    NotificationService.instance.cancelPersonalAmolReminder(slot);
    _ref.read(personalAmolRefreshProvider.notifier).bump();
  }

  Future<void> toggleComplete(PersonalAmolModel amol) async {
    final today = IslamicDateService.getCurrentIslamicDateStringSafe();
    if (!personalAmolScheduledOn(amol, today)) return;
    final existing = await _repo.getCompletionsForDate(_uid, today);
    final completed = existing.any((c) => c.amolId == amol.id);
    if (completed) {
      await _repo.unmarkComplete(_uid, amol.id, today);
    } else {
      await _repo.markComplete(_uid, amol.id, today);
    }
    await _recomputeStreak(amol.id);
    _ref.read(personalAmolRefreshProvider.notifier).bump();
  }

  /// Adds one counted completion for a count-type amol.
  Future<void> incrementCount(PersonalAmolModel amol) async {
    final today = IslamicDateService.getCurrentIslamicDateStringSafe();
    if (!personalAmolScheduledOn(amol, today)) return;
    await _repo.incrementCompletion(_uid, amol.id, today);
    await _recomputeStreak(amol.id);
    _ref.read(personalAmolRefreshProvider.notifier).bump();
  }

  /// Removes one counted completion for a count-type amol (no-op at zero).
  Future<void> decrementCount(PersonalAmolModel amol) async {
    final today = IslamicDateService.getCurrentIslamicDateStringSafe();
    final existing = await _repo.getCompletionsForDate(_uid, today);
    if (!existing.any((c) => c.amolId == amol.id)) return;
    await _repo.decrementCompletion(_uid, amol.id, today);
    await _recomputeStreak(amol.id);
    _ref.read(personalAmolRefreshProvider.notifier).bump();
  }

  Future<void> _recomputeStreak(String amolId) async {
    final amol = state[amolId];
    final completions = await _repo.getRecentCompletions(_uid);
    final loggedDates = completions
        .where((c) => c.amolId == amolId)
        // Only scheduled days count towards the streak, so a missed weekday
        // between two due days doesn't reset it.
        .where((c) => amol == null || personalAmolScheduledOn(amol, c.hijriDate))
        .map((c) => c.hijriDate)
        .toSet();
    final today = IslamicDateService.getCurrentIslamicDateStringSafe();
    final current = computeStreakFromLogs(
      loggedDates: loggedDates,
      todayHijri: today,
      // Unscheduled weekdays neither add to nor break a weekday amol's streak.
      scheduledWeekdays: amol != null &&
              amol.frequency == PersonalAmolFrequency.weekdays
          ? amol.weekdays.toSet()
          : const {},
    );
    final prev =
        (await _repo.watchStreak(_uid, amolId).first)
            ?.currentStreak ??
        0;
    // When there are no recorded completions, there is no streak: reset both
    // so a removed/unmarked completion doesn't leave a phantom "best" behind.
    final best = loggedDates.isEmpty ? 0 : (prev > current ? prev : current);
    await _repo.updateStreak(
      _uid,
      amolId,
      currentStreak: current,
      bestStreak: best,
    );
  }

  int _slotFor(String amolId) {
    var slot = 0;
    final ids = state.keys.toList()..sort();
    for (final id in ids) {
      if (id == amolId) return slot;
      slot++;
    }
    return state.length.clamp(0, AppConstants.kMaxFreePersonalAmol - 1);
  }

  Future<void> _scheduleReminderFor(
    PersonalAmolModel amol, {
    required int slot,
  }) async {
    final time = amol.reminderTime;
    if (time == null) {
      NotificationService.instance.cancelPersonalAmolReminder(slot);
      return;
    }
    await NotificationService.instance.schedulePersonalAmolReminder(
      slot: slot,
      name: amol.name,
      time: TimeOfDay(hour: time.hour, minute: time.minute),
    );
  }
}
