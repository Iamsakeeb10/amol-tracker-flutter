import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/services/analytics_service.dart';
import '../core/services/islamic_date_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/utils/personal_amol_schedule.dart';
import '../models/personal_amol_model.dart';
import 'date_provider.dart';
import 'personal_amol_provider.dart';

/// Staged (unsaved) personal-amol edits for today.
///
/// Mirrors the community-amol draft pattern (`AmalNotifier` in
/// `amal_provider.dart`): taps on the home toggle switch or +/− stepper only
/// mutate this in-memory draft — nothing touches Firestore until the save FAB
/// persists it via [PersonalAmolPendingNotifier.saveToday]. The draft is also
/// mirrored to Hive so it survives an app restart before the user saves.
class PersonalAmolPendingState {
  const PersonalAmolPendingState({
    this.staged = const {},
    this.baseline = const {},
    this.isSaving = false,
  });

  /// Desired completion count per [PersonalAmolModel.id] for today. Only amols
  /// with pending changes are present.
  final Map<String, int> staged;

  /// Saved (Firestore) completion count at the moment an amol was first staged,
  /// used to compute the net delta on save. Only amols with pending changes are
  /// present.
  final Map<String, int> baseline;

  /// True while a save is in flight (drives the FAB spinner).
  final bool isSaving;

  bool get dirty =>
      staged.entries.any((e) => (baseline[e.key] ?? 0) != e.value);

  PersonalAmolPendingState copyWith({
    Map<String, int>? staged,
    Map<String, int>? baseline,
    bool? isSaving,
  }) {
    return PersonalAmolPendingState(
      staged: staged ?? this.staged,
      baseline: baseline ?? this.baseline,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Pure staging helper, unit-testable without Firestore. Seeds [baseline] from
/// [baseCount] when the amol is first touched, records [desired] as the staged
/// value, and prunes the entry when it equals the baseline (no net change).
({
  Map<String, int> staged,
  Map<String, int> baseline,
}) stagePersonalAmolValue({
  required Map<String, int> staged,
  required Map<String, int> baseline,
  required String amolId,
  required int baseCount,
  required int desired,
}) {
  final nextStaged = Map<String, int>.from(staged);
  final nextBaseline = Map<String, int>.from(baseline);
  nextBaseline[amolId] = baseCount;
  if (desired == baseCount) {
    nextStaged.remove(amolId);
  } else {
    nextStaged[amolId] = desired;
  }
  nextBaseline.removeWhere((key, _) => !nextStaged.containsKey(key));
  return (staged: nextStaged, baseline: nextBaseline);
}

final personalAmolPendingProvider =
    StateNotifierProvider.family<
      PersonalAmolPendingNotifier,
      PersonalAmolPendingState,
      String
    >((ref, uid) => PersonalAmolPendingNotifier(ref, uid));

/// Owns the today-only pending personal-amol edits for one user.
class PersonalAmolPendingNotifier
    extends StateNotifier<PersonalAmolPendingState> {
  PersonalAmolPendingNotifier(this._ref, this._uid)
    : _date = IslamicDateService.getCurrentIslamicDateStringSafe(),
      super(const PersonalAmolPendingState()) {
    _restoreDraft();
    _ref.listen<String>(
      currentHijriDateProvider,
      (previous, next) => _handleDateChanged(previous, next),
    );
  }

  final Ref _ref;
  final String _uid;
  String _date;

  String _draftKeyFor(String date) => 'personal_amol_draft_${_uid}_$date';

  String get _draftKey => _draftKeyFor(_date);

  @override
  void dispose() {
    // Persist the latest draft on dispose. The snapshot is captured BEFORE
    // super.dispose() because reading `state` afterwards throws on the
    // disposed notifier.
    final staged = Map<String, int>.from(state.staged);
    final baseline = Map<String, int>.from(state.baseline);
    final date = _date;
    super.dispose();
    Future.microtask(() => _persistDraftFrom(staged, baseline, date));
  }

  void toggle(PersonalAmolModel amol) {
    final base = _baseFor(amol.id);
    final current = state.staged[amol.id] ?? base;
    final desired = current >= 1 ? 0 : 1;
    _stage(amol.id, base: base, desired: desired);
  }

  void plus(PersonalAmolModel amol) {
    final base = _baseFor(amol.id);
    final current = state.staged[amol.id] ?? base;
    final desired = (current + 1).clamp(0, amol.target);
    _stage(amol.id, base: base, desired: desired);
  }

  void minus(PersonalAmolModel amol) {
    final base = _baseFor(amol.id);
    final current = state.staged[amol.id] ?? base;
    final desired = (current - 1).clamp(0, 1 << 30);
    _stage(amol.id, base: base, desired: desired);
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
    // Persist without touching `state` again in case the notifier is disposed
    // before the microtask runs.
    final staged = Map<String, int>.from(state.staged);
    final baseline = Map<String, int>.from(state.baseline);
    final date = _date;
    Future.microtask(() => _persistDraftFrom(staged, baseline, date));
  }

  int _baseFor(String amolId) {
    final seeded = state.baseline[amolId];
    if (seeded != null) return seeded;
    final base = _ref
        .read(personalAmolCompletionsForTodayProvider(_uid))
        .value;
    return base?.where((c) => c.amolId == amolId).length ?? 0;
  }

  /// Persists the staged changes for the current Hijri day so they survive an
  /// app restart before the user presses Save (mirrors the community draft).
  Future<void> _persistDraft() => _persistDraftFrom(
        Map<String, int>.from(state.staged),
        Map<String, int>.from(state.baseline),
        _date,
      );

  Future<void> _persistDraftFrom(
    Map<String, int> staged,
    Map<String, int> baseline,
    String date,
  ) async {
    final dirty = staged.entries.any((e) => (baseline[e.key] ?? 0) != e.value);
    final key = _draftKeyFor(date);
    if (dirty) {
      await LocalStorageService.saveLog(key, {
        'date': date,
        'staged': staged,
        'baseline': baseline,
      });
    } else {
      await LocalStorageService.deleteLog(key);
    }
  }

  void _restoreDraft() {
    final data = LocalStorageService.getLog(_draftKey);
    if (data == null) return;
    final savedDate = data['date'];
    if (savedDate != _date) {
      LocalStorageService.deleteLog(_draftKeyFor('$savedDate'));
      return;
    }
    final staged = _intMap(data['staged']);
    final baseline = _intMap(data['baseline']);
    state = PersonalAmolPendingState(
      staged: staged,
      baseline: baseline,
    );
  }

  void _handleDateChanged(String? previous, String next) {
    if (next == _date) return;
    // Drop in-flight edits (and their stale Hive draft) when the day rolls
    // over — staged edits only ever belong to the day they were made.
    LocalStorageService.deleteLog(_draftKeyFor(_date));
    _date = next;
    state = const PersonalAmolPendingState();
  }

  /// Persists all staged edits for today in batched Firestore writes, then
  /// recomputes streaks once per affected amol. Called by the save FAB.
  Future<void> saveToday() async {
    if (state.isSaving || !state.dirty) return;
    state = state.copyWith(isSaving: true);
    final entries = List<MapEntry<String, int>>.from(state.staged.entries);
    final today = _date;
    final repo = _ref.read(personalAmolRepositoryProvider);
    final amolNotifier = _ref.read(personalAmolNotifierProvider(_uid).notifier);

    Map<String, PersonalAmolModel> amolMap = amolNotifier.state;
    if (amolMap.isEmpty || entries.any((e) => !amolMap.containsKey(e.key))) {
      try {
        final list = await repo.watchAllAmol(_uid).first;
        amolMap = {for (final a in list) a.id: a};
      } catch (_) {}
    }

    final applied = <String>{};
    var amolsChanged = 0;
    for (final entry in entries) {
      final amol = amolMap[entry.key];
      if (amol == null || !personalAmolScheduledOn(amol, today)) {
        // Stale entry (deleted or no longer scheduled today): drop it.
        applied.add(entry.key);
        continue;
      }
      final baseline = state.baseline[entry.key] ?? 0;
      final delta = entry.value - baseline;
      if (delta == 0) {
        applied.add(entry.key);
        continue;
      }
      try {
        await repo.applyCompletionDelta(
          _uid,
          entry.key,
          today,
          delta,
          isToggle: amol.type == PersonalAmolType.toggle,
        );
        applied.add(entry.key);
        amolsChanged++;

        // Fire completion/uncompletion events based on whether this amol
        // crossed its target threshold.
        final target = amol.type == PersonalAmolType.count ? amol.target : 1;
        final typeLabel = amol.type == PersonalAmolType.count ? 'count' : 'toggle';
        final freqLabel = amol.frequency == PersonalAmolFrequency.daily
            ? 'daily'
            : 'weekdays';
        final wasComplete = baseline >= target;
        final isComplete = entry.value >= target;
        if (!wasComplete && isComplete) {
          AnalyticsService.instance.logPersonalAmolCompleted(
            type: typeLabel,
            frequency: freqLabel,
          );
        } else if (wasComplete && !isComplete) {
          AnalyticsService.instance.logPersonalAmolUncompleted(
            type: typeLabel,
            frequency: freqLabel,
          );
        }

        // Streak is best-effort; never let a streak read/write failure block
        // or revert the already-persisted completion delta.
        try {
          await amolNotifier.recomputeStreak(entry.key);
        } catch (_) {
          // non-critical
        }
      } catch (_) {
        // Leave this amol staged so a retry re-applies only this one,
        // never duplicating already-saved deltas.
      }
    }
    if (applied.isNotEmpty) {
      _ref.read(personalAmolRefreshProvider.notifier).bump();
    }
    // Fire a single 'saved' event for the whole batch.
    if (amolsChanged > 0) {
      AnalyticsService.instance.logPersonalAmolSaved(
        amolsChanged: amolsChanged,
      );
    }
    // Drop applied/stale entries, keep anything that failed for a retry.
    final remaining = Map<String, int>.from(state.staged)
      ..removeWhere((key, _) => applied.contains(key));
    state = PersonalAmolPendingState(
      staged: remaining,
      baseline: Map<String, int>.from(state.baseline)
        ..removeWhere((key, _) => !remaining.containsKey(key)),
    );
    if (state.dirty) {
      await _persistDraft();
    } else {
      await LocalStorageService.deleteLog(_draftKey);
    }
  }

  static Map<String, int> _intMap(Object? raw) {
    if (raw is! Map) return <String, int>{};
    return raw.map(
      (key, value) => MapEntry('$key', (value as num).toInt()),
    );
  }
}