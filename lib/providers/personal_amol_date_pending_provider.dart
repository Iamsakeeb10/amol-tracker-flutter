import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/services/islamic_date_service.dart';
import '../core/utils/personal_amol_schedule.dart';
import '../models/personal_amol_model.dart';
import 'personal_amol_home_lock_provider.dart';
import 'personal_amol_pending_provider.dart';
import 'personal_amol_provider.dart';

/// Runs the day-detail personal-amol editing flow.
///
/// Today's home screen stages personal-amol edits into the today-only
/// [personalAmolPendingProvider]. The day-history detail screen needs the same
/// "tap to stage, save to persist" behaviour for an arbitrary viewed Hijri
/// date, so it uses a per-date family keyed by (uid, hijriDate). Edits only
/// touch Firestore when the per-date Save button calls [save].
class PersonalAmolDateEditKey {
  const PersonalAmolDateEditKey({
    required this.uid,
    required this.hijriDate,
  });

  final String uid;
  final String hijriDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalAmolDateEditKey &&
          uid == other.uid &&
          hijriDate == other.hijriDate;

  @override
  int get hashCode => Object.hash(uid, hijriDate);
}

final personalAmolDatePendingProvider = StateNotifierProvider.family<
  PersonalAmolDatePendingNotifier,
  PersonalAmolPendingState,
  PersonalAmolDateEditKey
>((ref, key) => PersonalAmolDatePendingNotifier(ref, key.uid, key.hijriDate));

/// Owns the staged (unsaved) personal-amol completions for one specific Hijri
/// date, so the day-detail screen can offer home-style toggle/+/− editing.
class PersonalAmolDatePendingNotifier
    extends StateNotifier<PersonalAmolPendingState> {
  PersonalAmolDatePendingNotifier(this._ref, this._uid, this._hijriDate)
    : super(const PersonalAmolPendingState());

  final Ref _ref;
  final String _uid;
  final String _hijriDate;

  void toggle(PersonalAmolModel amol) {
    final base = _baseFor(amol.id);
    final current = state.staged[amol.id] ?? base;
    _stage(amol.id, base: base, desired: current >= 1 ? 0 : 1);
  }

  void plus(PersonalAmolModel amol) {
    final base = _baseFor(amol.id);
    final current = state.staged[amol.id] ?? base;
    _stage(amol.id, base: base, desired: (current + 1).clamp(0, amol.target));
  }

  void minus(PersonalAmolModel amol) {
    final base = _baseFor(amol.id);
    final current = state.staged[amol.id] ?? base;
    _stage(amol.id, base: base, desired: (current - 1).clamp(0, 1 << 30));
  }

  void _stage(String amolId, {required int base, required int desired}) {
    final next = stagePersonalAmolValue(
      staged: state.staged,
      baseline: state.baseline,
      amolId: amolId,
      baseCount: base,
      desired: desired,
    );
    state = PersonalAmolPendingState(
      staged: next.staged,
      baseline: next.baseline,
    );
  }

  int _baseFor(String amolId) {
    final seeded = state.baseline[amolId];
    if (seeded != null) return seeded;
    final base = _ref
        .read(
          personalAmolCompletionsForDateProvider(
            PersonalAmolDateKey(uid: _uid, hijriDate: _hijriDate),
          ),
        )
        .value;
    return base?.where((c) => c.amolId == amolId).length ?? 0;
  }

  /// Persists all staged edits for the viewed date in one batched write per
  /// amol (via the existing delta engine), then recomputes streaks best-effort
  /// and refreshes dependent views.
  ///
  /// Returns `true` when at least one amol write succeeded.
  Future<bool> save() async {
    if (state.isSaving || !state.dirty) return false;
    state = state.copyWith(isSaving: true);
    final repo = _ref.read(personalAmolRepositoryProvider);
    final amolNotifier = _ref.read(personalAmolNotifierProvider(_uid).notifier);
    final entries = List<MapEntry<String, int>>.from(state.staged.entries);

    Map<String, PersonalAmolModel> amolMap = amolNotifier.state;
    if (amolMap.isEmpty || entries.any((e) => !amolMap.containsKey(e.key))) {
      try {
        final list = await repo.watchAllAmol(_uid).first;
        amolMap = {for (final a in list) a.id: a};
      } catch (_) {}
    }

    final applied = <String>{};
    var wroteAny = false;
    for (final entry in entries) {
      final amol = amolMap[entry.key];
      if (amol == null || !personalAmolScheduledOn(amol, _hijriDate)) {
        applied.add(entry.key);
        continue;
      }
      final delta = entry.value - (state.baseline[entry.key] ?? 0);
      if (delta == 0) {
        applied.add(entry.key);
        continue;
      }
      try {
        await repo.applyCompletionDelta(
          _uid,
          entry.key,
          _hijriDate,
          delta,
          isToggle: amol.type == PersonalAmolType.toggle,
        );
        applied.add(entry.key);
        wroteAny = true;
        try {
          await amolNotifier.recomputeStreak(entry.key);
        } catch (_) {
          // non-critical
        }
        // Only today's progress belongs in the daily reminder notification.
        final today = IslamicDateService.getCurrentIslamicDateStringSafe();
        if (amol.reminderTime != null && _hijriDate == today) {
          unawaited(
            amolNotifier.refreshReminder(amol, doneToday: entry.value),
          );
        }
      } catch (_) {
        // Leave this amol staged so a retry applies only this one.
      }
    }
    if (applied.isNotEmpty) {
      _ref.read(personalAmolRefreshProvider.notifier).bump();
    }

    // Keep applied counts in [staged] and sync [baseline] so the UI overlay
    // stays correct while completions re-fetch. Clearing staged immediately
    // would flash the pre-save (stale) completions until the refresh lands.
    final nextStaged = Map<String, int>.from(state.staged);
    final nextBaseline = Map<String, int>.from(state.baseline);
    for (final id in applied) {
      final desired = state.staged[id];
      if (desired == null) {
        nextStaged.remove(id);
        nextBaseline.remove(id);
      } else {
        nextStaged[id] = desired;
        nextBaseline[id] = desired;
      }
    }
    state = PersonalAmolPendingState(
      staged: nextStaged,
      baseline: nextBaseline,
      isSaving: false,
    );
    // After a clean save for today, lock home personal tiles (independent of
    // community submit). Past-day saves must not touch today's lock.
    final today = IslamicDateService.getCurrentIslamicDateStringSafe();
    if (_hijriDate == today && !state.dirty) {
      await markPersonalAmolHomeLocked(
        _ref,
        uid: _uid,
        hijriDate: today,
      );
    }
    return wroteAny;
  }
}
