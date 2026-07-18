import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/constants/amal_fields.dart';
import '../core/constants/default_amal_fields.dart';
import '../core/services/analytics_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/islamic_date_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/notification_service.dart';
import '../core/utils/hijri_helper.dart';
import '../core/utils/score_calculator.dart';
import '../core/utils/streak_helper.dart';
import '../features/widget/home_widget_service.dart';
import '../models/amal_log_model.dart';
import '../models/badge_model.dart';
import '../models/user_model.dart';
import 'amal_fields_provider.dart';
import 'auth_provider.dart';
import 'date_provider.dart';
import 'history_provider.dart';
import 'locale_provider.dart';

/// Network status for offline banner (Phase 3).
final connectivityListProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) async* {
  yield await Connectivity().checkConnectivity();
  yield* Connectivity().onConnectivityChanged;
});

Map<String, dynamic> _emptyTogglesForFields(List<AmalField> fields) {
  return <String, dynamic>{
    for (final f in fields) f.id: f.type == AmalType.numeric ? 0 : false,
  };
}

/// Serialize lit-circle selections for the local draft (Set -> sorted List).
Map<String, List<int>> _serializePrayerSelections(
  Map<String, Set<int>> selections,
) {
  return <String, List<int>>{
    for (final entry in selections.entries)
      entry.key: (entry.value.toList()..sort()),
  };
}

/// Parse persisted lit-circle selections from a draft map.
Map<String, Set<int>> _parsePrayerSelections(dynamic raw) {
  if (raw is! Map) return <String, Set<int>>{};
  final result = <String, Set<int>>{};
  raw.forEach((key, value) {
    if (value is List) {
      result[key.toString()] = value
          .map((e) => (e as num?)?.toInt())
          .whereType<int>()
          .toSet();
    }
  });
  return result;
}

/// Keep only expandable fields and reconcile each selection with its count.
Map<String, Set<int>> _reconcilePrayerSelections(
  Map<String, Set<int>> stored,
  Map<String, dynamic> toggles,
  List<AmalField> fields,
) {
  final result = <String, Set<int>>{};
  for (final field in fields) {
    if (!field.supportsExpansion) continue;
    final count = getNumericValue(toggles[field.id], field.maxValue);
    if (count <= 0) continue;
    result[field.id] =
        resolvePrayerSelection(stored[field.id], count, field.maxValue);
  }
  return result;
}

bool _isPerfectWeekChain(List<AmalLogModel> logs) {
  if (logs.length < 7) return false;
  final chain = logs.sublist(logs.length - 7);
  for (var i = 1; i < chain.length; i++) {
    final expected = IslamicDateService.shiftStorageByDays(
      chain[i - 1].hijriDate,
      1,
    );
    if (chain[i].hijriDate != expected) return false;
  }
  return true;
}

int _streakAfterFreeze(int currentStreak) => streakAfterFreeze(currentStreak);

class AmalState {
  const AmalState({
    required this.toggles,
    required this.fields,
    required this.isSubmitted,
    required this.isLoading,
    this.error,
    this.submittedLog,
    this.prayerSelections = const <String, Set<int>>{},
  });

  factory AmalState.initial({List<AmalField> fields = const []}) {
    return AmalState(
      toggles: _emptyTogglesForFields(fields),
      fields: fields,
      isSubmitted: false,
      isLoading: true,
    );
  }

  final Map<String, dynamic> toggles;
  final List<AmalField> fields;
  final bool isSubmitted;
  final bool isLoading;
  final String? error;
  final AmalLogModel? submittedLog;

  /// UI-only positions of lit prayer circles per expandable field id. Persisted
  /// to the local draft (not Firestore, which keeps count-only toggles).
  final Map<String, Set<int>> prayerSelections;

  int get doneCount {
    final activeIds = resolveAmalFields(fields).map((f) => f.id).toSet();
    return toggles.entries
        .where((e) => activeIds.contains(e.key))
        .where((e) => e.value == true || (e.value is int && e.value > 0))
        .length;
  }

  int get totalScore => calculateScore(toggles, fields);

  int get maxScore => getMaxScore(fields).clamp(1, kDefaultMaxDailyScore);

  bool get hasAnyDone {
    final activeIds = resolveAmalFields(fields).map((f) => f.id).toSet();
    return toggles.entries
        .where((e) => activeIds.contains(e.key))
        .any((e) => e.value == true || (e.value is int && e.value > 0));
  }

  AmalState copyWith({
    Map<String, dynamic>? toggles,
    List<AmalField>? fields,
    bool? isSubmitted,
    bool? isLoading,
    String? error,
    AmalLogModel? submittedLog,
    Map<String, Set<int>>? prayerSelections,
    bool clearError = false,
    bool clearSubmittedLog = false,
  }) {
    return AmalState(
      toggles: toggles ?? this.toggles,
      fields: fields ?? this.fields,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      submittedLog: clearSubmittedLog
          ? null
          : (submittedLog ?? this.submittedLog),
      prayerSelections: prayerSelections ?? this.prayerSelections,
    );
  }
}

/// Returned from [AmalNotifier.submit] after a successful local submit.
class SubmitResult {
  const SubmitResult({required this.log, required this.streakResult});

  final AmalLogModel log;
  final StreakResult streakResult;
}

final amalProvider =
    StateNotifierProvider.family<AmalNotifier, AmalState, String>(
      (ref, uid) => AmalNotifier(ref, uid),
    );

class AmalNotifier extends StateNotifier<AmalState> {
  AmalNotifier(this._ref, this._uid) : super(AmalState.initial()) {
    Future<void>.microtask(_load);
    _ref.listen<String>(currentHijriDateProvider, (prev, next) {
      if (prev == null || prev == next) return;
      reloadForNewDay();
    });
    _ref.listen<AsyncValue<List<AmalField>>>(amalFieldsProvider, (prev, next) {
      next.whenData((fields) {
        if (fields.isEmpty) return;
        if (listEquals(state.fields, fields)) return;
        _applyFields(fields);
      });
    });
  }

  final Ref _ref;
  final String _uid;

  /// Re-sync today's log after a manual fields refresh (Retry).
  Future<void> refreshFromFields() => _load();

  /// Clear stale toggles and reload when the Islamic day rolls over.
  Future<void> reloadForNewDay() async {
    final fields = state.fields.isNotEmpty ? state.fields : const <AmalField>[];
    state = AmalState(
      toggles: _emptyTogglesForFields(fields),
      fields: fields,
      isSubmitted: false,
      isLoading: true,
    );
    await _load();
  }

  /// Push the current state to the home widget immediately.
  /// Pass [streakOverride] when the caller already has the resolved streak
  /// value (e.g. home screen) so we don't have to wait for currentUserProvider.
  Future<void> refreshWidgetData({int? streakOverride}) =>
      _updateHomeWidget(streakOverride: streakOverride);


  void _applyFields(List<AmalField> fields) {
    final nextToggles = normalizeTogglesForFields(state.toggles, fields);
    state = state.copyWith(
      toggles: nextToggles,
      fields: fields,
      prayerSelections: _reconcilePrayerSelections(
        state.prayerSelections,
        nextToggles,
        fields,
      ),
      clearError: true,
    );
  }

  String _submittedHiveKey(String hijri) => 'log_${_uid}_$hijri';

  String _draftHiveKey(String hijri) => 'draft_${_uid}_$hijri';

  /// Key for the lit-circle positions that accompany a submitted/edited log.
  /// Stored separately from the log map so we never risk corrupting the log.
  String _selectionsHiveKey(String hijri) => 'selections_${_uid}_$hijri';

  Future<void> _trySyncSubmittedLog(AmalLogModel log) async {
    try {
      final fs = _ref.read(firestoreServiceProvider);
      await fs.saveAmalLog(log, state.fields);
      await fs.updateUserLastLogDate(log.uid, log.hijriDate);
    } catch (_) {
      // Keep local cache as source until sync succeeds.
    }
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    List<AmalField> fields;
    try {
      fields = await _ref.read(amalFieldsProvider.future);
    } catch (_) {
      fields = kDefaultAmalFields;
    }
    if (fields.isEmpty) {
      fields = kDefaultAmalFields;
    }

    final hijri = _ref.read(currentHijriDateProvider);
    final fs = _ref.read(firestoreServiceProvider);

    try {
      final fromFs = await fs.getTodayLog(_uid, hijri);
      if (fromFs != null) {
        final normalizedToggles =
            normalizeTogglesForFields(fromFs.toggles, fields);
        // Restore the exact prayer-circle positions saved locally (if any).
        // Firestore only stores counts, so without this the UI would default
        // to a left-to-right fill (Fajr+Dhuhr) instead of the actual prayers.
        final storedSelections = _parsePrayerSelections(
          LocalStorageService.getLog(_selectionsHiveKey(hijri)),
        );
        final resolvedSelections = _reconcilePrayerSelections(
          storedSelections,
          normalizedToggles,
          fields,
        );
        state = AmalState(
          toggles: normalizedToggles,
          fields: fields,
          isSubmitted: true,
          isLoading: false,
          submittedLog: fromFs,
          prayerSelections: resolvedSelections,
        );
        await LocalStorageService.saveLog(
          _submittedHiveKey(hijri),
          fromFs.toHiveMap(),
        );
        // Update home widget when loading from Firestore
        await _updateHomeWidget();
        return;
      }
    } catch (_) {
      // Offline or error — try Hive cache.
    }

    final cached = LocalStorageService.getLog(_submittedHiveKey(hijri));
    if (cached != null) {
      try {
        final model = AmalLogModel.fromHiveMap(cached);
        if (model.uid == _uid && model.hijriDate == hijri) {
          final normalizedToggles =
              normalizeTogglesForFields(model.toggles, fields);
          final storedSelections = _parsePrayerSelections(
            LocalStorageService.getLog(_selectionsHiveKey(hijri)),
          );
          final resolvedSelections = _reconcilePrayerSelections(
            storedSelections,
            normalizedToggles,
            fields,
          );
          state = AmalState(
            toggles: normalizedToggles,
            fields: fields,
            isSubmitted: true,
            isLoading: false,
            submittedLog: model,
            prayerSelections: resolvedSelections,
          );
          // Update home widget when loading from Hive cache
          await _updateHomeWidget();
          Future<void>.microtask(() => _trySyncSubmittedLog(model));
          return;
        }
      } catch (_) {}
    }

    final draft = LocalStorageService.getLog(_draftHiveKey(hijri));
    if (draft != null && draft['uid'] == _uid) {
      final rawToggles = draft['toggles'];
      if (rawToggles is Map) {
        final next = normalizeTogglesForFields(
          Map<String, dynamic>.from(rawToggles),
          fields,
        );
        final storedSelections = _parsePrayerSelections(
          draft['prayerSelections'],
        );
        state = AmalState(
          toggles: next,
          fields: fields,
          isSubmitted: false,
          isLoading: false,
          prayerSelections: _reconcilePrayerSelections(
            storedSelections,
            next,
            fields,
          ),
        );
        // Update home widget when loading from draft
        await _updateHomeWidget();
        return;
      }
    }

    state = AmalState(
      toggles: _emptyTogglesForFields(fields),
      fields: fields,
      isSubmitted: false,
      isLoading: false,
    );
    // Update home widget on initial load
    await _updateHomeWidget();
  }

  Future<void> _persistDraft() async {
    if (state.isSubmitted) return;
    final hijri = IslamicDateService.getCurrentIslamicDateStringSafe();
    await LocalStorageService.saveLog(_draftHiveKey(hijri), <String, dynamic>{
      'uid': _uid,
      'hijriDate': hijri,
      'toggles': Map<String, dynamic>.from(state.toggles),
      'prayerSelections': _serializePrayerSelections(state.prayerSelections),
    });
    await _updateHomeWidget();
  }

  Future<void> _updateHomeWidget({int? streakOverride}) async {
    try {
      final hijriDisplay = IslamicDateService.getDisplayIslamicDate();
      final score = state.totalScore;
      final maxScore = state.maxScore;
      final completedCount = state.doneCount;
      final activeFields = HomeWidgetService.getActiveFields(state.fields);
      final totalCount = activeFields.length;

      // Use the same live streak source as the home screen, bottom sheet,
      // and profile screens. Fall back to Firestore only if the provider
      // hasn't loaded yet.
      final user = _ref.read(currentUserProvider).asData?.value;
      final liveStreak = _ref.read(liveStreakProvider).value;
      final streak = streakOverride ?? liveStreak ?? user?.currentStreak ?? 0;

      await HomeWidgetService.updateWidget(
        hijriDateDisplay: hijriDisplay,
        score: score,
        maxScore: maxScore,
        completedCount: completedCount,
        totalCount: totalCount,
        isSubmitted: state.isSubmitted,
        toggles: state.toggles,
        fields: state.fields,
        currentStreak: streak,
      );
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }

  void toggle(String fieldId) {
    if (state.isSubmitted || state.isLoading) return;
    final field = state.fields.where((f) => f.id == fieldId).firstOrNull;
    if (field == null || field.type != AmalType.boolean) return;
    final next = Map<String, dynamic>.from(state.toggles);
    next[fieldId] = !((next[fieldId] as bool?) ?? false);
    state = state.copyWith(toggles: next, clearError: true);
    Future<void>.microtask(_persistDraft);
  }

  void setNumeric(String fieldId, int value) {
    if (state.isSubmitted || state.isLoading) return;
    final field = state.fields.where((f) => f.id == fieldId).firstOrNull;
    if (field == null || field.type != AmalType.numeric) return;

    final nextValue = value.clamp(0, field.maxValue);

    final next = Map<String, dynamic>.from(state.toggles);
    next[fieldId] = nextValue;

    // Direct count changes reconcile the lit circles to a left-to-right fill.
    Map<String, Set<int>>? nextSelections;
    if (field.supportsExpansion) {
      nextSelections = Map<String, Set<int>>.from(state.prayerSelections);
      nextSelections[fieldId] = <int>{for (var i = 0; i < nextValue; i++) i};
    }

    state = state.copyWith(
      toggles: next,
      prayerSelections: nextSelections,
      clearError: true,
    );
    Future<void>.microtask(_persistDraft);
  }

  /// Toggle a single prayer circle for an expandable field. Keeps the stored
  /// count in sync (count = number of lit circles) while remembering the exact
  /// positions so each prayer can be toggled independently.
  void togglePrayer(String fieldId, int index) {
    if (state.isSubmitted || state.isLoading) return;
    final field = state.fields.where((f) => f.id == fieldId).firstOrNull;
    if (field == null || !field.supportsExpansion) return;
    if (index < 0 || index >= field.maxValue) return;

    final currentCount = getNumericValue(state.toggles[fieldId], field.maxValue);
    final base = resolvePrayerSelection(
      state.prayerSelections[fieldId],
      currentCount,
      field.maxValue,
    );
    final nextSet = Set<int>.from(base);
    if (!nextSet.remove(index)) nextSet.add(index);

    final nextToggles = Map<String, dynamic>.from(state.toggles);
    nextToggles[fieldId] = nextSet.length;
    final nextSelections = Map<String, Set<int>>.from(state.prayerSelections);
    nextSelections[fieldId] = nextSet;

    state = state.copyWith(
      toggles: nextToggles,
      prayerSelections: nextSelections,
      clearError: true,
    );
    Future<void>.microtask(_persistDraft);
  }

  void markAllDone() {
    if (state.isSubmitted || state.isLoading) return;
    final activeFields = resolveAmalFields(state.fields);
    final next = Map<String, dynamic>.from(state.toggles);
    final nextSelections = Map<String, Set<int>>.from(state.prayerSelections);
    for (final f in activeFields) {
      next[f.id] = f.type == AmalType.numeric ? f.maxValue : true;
      if (f.supportsExpansion) {
        nextSelections[f.id] = <int>{for (var i = 0; i < f.maxValue; i++) i};
      }
    }
    state = state.copyWith(
      toggles: next,
      prayerSelections: nextSelections,
      clearError: true,
    );
    Future<void>.microtask(_persistDraft);
  }

  void clearAll() {
    if (state.isSubmitted || state.isLoading) return;
    state = state.copyWith(
      toggles: _emptyTogglesForFields(state.fields),
      prayerSelections: const <String, Set<int>>{},
      clearError: true,
    );
    Future<void>.microtask(_persistDraft);
  }

  Future<void> applyFreeze(UserModel user, {
    required String hijri,
    required int preservedStreak,
  }) async {
    final fs = _ref.read(firestoreServiceProvider);
    final frozenDate = IslamicDateService.shiftStorageByDays(hijri, -1);
    final newCurrent = preservedStreak + 2;
    final newBest = newCurrent > user.bestStreak ? newCurrent : user.bestStreak;
    await fs.updateStreak(
      user.uid,
      streakFreezeUsed: true,
      streakFreezeWeekKey: weekKeyFromDate(HijriHelper.bangladeshNow()),
      currentStreak: newCurrent,
      bestStreak: newBest,
      lastLogDate: hijri,
      streakFreezeDate: frozenDate,
    );
    AnalyticsService.instance.logStreakFreezeUsed(streakDays: newCurrent);
  }

  Future<void> resetStreak(String uid) async {
    final fs = _ref.read(firestoreServiceProvider);
    await fs.updateStreak(uid, currentStreak: 1, streakFreezeDate: '');
  }

  Future<SubmitResult?> submit(UserModel user) async {
    if (state.isSubmitted || state.isLoading) return null;
    if (!state.hasAnyDone) {
      state = state.copyWith(
        error: 'Toggle at least one amal before submitting.',
      );
      return null;
    }

    final hijri = IslamicDateService.getCurrentIslamicDateStringSafe();
    final toggles = normalizeTogglesForFields(state.toggles, state.fields);
    final score = calculateScore(toggles, state.fields);
    final now = DateTime.now().toUtc();
    final currentWeekKey = weekKeyFromDate(HijriHelper.bangladeshNow());
    final freezeAvailableThisWeek = user.streakFreezeWeekKey != currentWeekKey
        ? true
        : !user.streakFreezeUsed;

    final log = AmalLogModel(
      uid: user.uid,
      displayName: user.name,
      photoUrl: user.photoUrl,
      isAnonymousDisplay: user.isAnonymousDisplay,
      hijriDate: hijri,
      toggles: toggles,
      score: score,
      submittedAt: now,
      prayers: _serializePrayerSelections(state.prayerSelections),
    );

    var streakResult = computeStreakResult(
      lastLogDate: user.lastLogDate,
      todayHijri: hijri,
      currentStreak: user.currentStreak,
      bestStreak: user.bestStreak,
      streakFreezeUsed: !freezeAvailableThisWeek,
    );

    state = state.copyWith(isLoading: true, clearError: true);
    String? submitWarning;

    try {
      final fs = _ref.read(firestoreServiceProvider);
      await fs.saveAmalLog(log, state.fields);
      AnalyticsService.instance.logAmalCompleted(score: score);
      AnalyticsService.instance.logDailyScoreCompleted(totalScore: score);

      // Recompute preserved streak from actual logs when showing freeze modal,
      // to avoid stale Firestore currentStreak causing inconsistent counts.
      if (streakResult.action == StreakAction.showFreeze) {
        final recentLogs = await fs.getRecentLogs(user.uid, limit: 30);
        final loggedDates = <String>{
          for (final log in recentLogs)
            if (!isBackfilledLog(log)) log.hijriDate,
          hijri, // Include today's just-saved log
        };
        final preservedStreak = computeStreakFromLogs(
          loggedDates: loggedDates,
          todayHijri: hijri,
        );
        streakResult = StreakResult(
          action: StreakAction.showFreeze,
          newCurrentStreak: preservedStreak,
          newBestStreak: streakResult.newBestStreak,
        );
      }

      // Field-level tracking
      final nowLocal = DateTime.now();
      final dayOfWeek = _dayOfWeekName(nowLocal.weekday);
      final hijriMonth = _hijriMonthFromStorage(hijri);
      for (final entry in toggles.entries) {
        AnalyticsService.instance.logAmalFieldSubmitted(
          fieldId: entry.key,
          value: entry.value,
          dayOfWeek: dayOfWeek,
          hijriMonth: hijriMonth,
        );
      }

      // Submission timing
      AnalyticsService.instance.logAmalSubmissionTiming(
        hourOfDay: nowLocal.hour,
        score: score,
        isLastMinute: nowLocal.hour >= 22,
      );

      // Update user properties
      final locale = _ref.read(localeProvider).languageCode;
      final totalSubmissions = user.currentStreak + 1;
      AnalyticsService.instance.updateUserProperties(
        currentStreak: streakResult.newCurrentStreak,
        totalSubmissions: totalSubmissions,
        locale: locale,
      );
      // Ensure lastLogDate is always updated when the log is saved,
      // even if the full updateStreak call fails.
      unawaited(fs.updateUserLastLogDate(user.uid, hijri).catchError((_) {}));
      try {
        switch (streakResult.action) {
          case StreakAction.increment:
            AnalyticsService.instance.logStreakExtended(
              streakDays: streakResult.newCurrentStreak,
            );
            await fs.updateStreak(
              user.uid,
              currentStreak: streakResult.newCurrentStreak,
              bestStreak: streakResult.newBestStreak,
              streakFreezeUsed: user.streakFreezeWeekKey != currentWeekKey
                  ? false
                  : user.streakFreezeUsed,
              streakFreezeWeekKey: currentWeekKey,
              lastLogDate: hijri,
            );
            await _syncClientSideBadgesAndFeed(
              fs: fs,
              user: user,
              submittedLog: log,
              resultingCurrentStreak: streakResult.newCurrentStreak,
              currentWeekKey: currentWeekKey,
            );
            break;
          case StreakAction.reset:
            AnalyticsService.instance.logStreakLost(
              previousStreak: user.currentStreak,
            );
            await fs.updateStreak(
              user.uid,
              currentStreak: streakResult.newCurrentStreak,
              bestStreak: streakResult.newBestStreak,
              streakFreezeUsed: user.streakFreezeWeekKey != currentWeekKey
                  ? false
                  : user.streakFreezeUsed,
              streakFreezeWeekKey: currentWeekKey,
              lastLogDate: hijri,
            );
            await _syncClientSideBadgesAndFeed(
              fs: fs,
              user: user,
              submittedLog: log,
              resultingCurrentStreak: streakResult.newCurrentStreak,
              currentWeekKey: currentWeekKey,
            );
            break;
          case StreakAction.showFreeze:
            await fs.updateStreak(
              user.uid,
              streakFreezeUsed: user.streakFreezeWeekKey != currentWeekKey
                  ? false
                  : user.streakFreezeUsed,
              streakFreezeWeekKey: currentWeekKey,
              lastLogDate: hijri,
            );
            await _syncClientSideBadgesAndFeed(
              fs: fs,
              user: user,
              submittedLog: log,
              resultingCurrentStreak: _streakAfterFreeze(streakResult.newCurrentStreak),
              currentWeekKey: currentWeekKey,
            );
            break;
        }
      } catch (e) {
        // Streak fields can sync later; log doc is saved.
      }
    } catch (e, st) {
      AnalyticsService.instance.recordError(e, st, reason: 'Amal submit failed');
      submitWarning = 'Saved locally - will sync when back online.';
    } finally {
      await LocalStorageService.saveLog(
        _submittedHiveKey(hijri),
        log.toHiveMap(),
      );
      await LocalStorageService.deleteLog(_draftHiveKey(hijri));
      // Persist the exact prayer-circle positions so they can be restored
      // when the app reloads (Firestore only stores the count, not positions).
      final submittedSelections = state.prayerSelections;
      if (submittedSelections.isNotEmpty) {
        await LocalStorageService.saveLog(
          _selectionsHiveKey(hijri),
          _serializePrayerSelections(submittedSelections)
              .map((k, v) => MapEntry(k, v)),
        );
      }

      state = AmalState(
        toggles: toggles,
        fields: state.fields,
        isSubmitted: true,
        isLoading: false,
        error: submitWarning,
        submittedLog: log,
        prayerSelections: submittedSelections,
      );
      await _updateHomeWidget(
        streakOverride: streakResult.action == StreakAction.showFreeze
            ? _streakAfterFreeze(streakResult.newCurrentStreak)
            : streakResult.newCurrentStreak,
      );
    }
    _ref.invalidate(historyMonthProvider);
    _ref.read(amalLogRefreshProvider.notifier).bump();
    Future<void>.microtask(() => _trySyncSubmittedLog(log));

    // Cancel smart reminders since user just logged
    final locale = _ref.read(localeProvider).languageCode;
    unawaited(
      NotificationService.instance.scheduleSmartReminders(
        uid: user.uid,
        currentStreak: streakResult.newCurrentStreak,
        lastLogDate: hijri,
        locale: locale,
      ),
    );

    return SubmitResult(log: log, streakResult: streakResult);
  }

  Future<void> _syncClientSideBadgesAndFeed({
    required FirestoreService fs,
    required UserModel user,
    required AmalLogModel submittedLog,
    required int resultingCurrentStreak,
    required String currentWeekKey,
  }) async {
    final nextBadges = <String>{...user.badges};
    final maxScore = getMaxScore(state.fields).clamp(1, kDefaultMaxDailyScore);

    // Recompute streak from actual logs instead of using the potentially
    // stale Firestore currentStreak, so badges match what the UI shows.
    final badgeLogs = await fs.getRecentLogs(user.uid, limit: 30);
    final badgeToday = IslamicDateService.getCurrentIslamicDateStringSafe();
    final badgeLoggedDates = <String>{
      for (final log in badgeLogs)
        if (!isBackfilledLog(log)) log.hijriDate,
    };
    final badgeFrozenDates = <String>{
      if (user.streakFreezeDate.isNotEmpty) user.streakFreezeDate,
    };
    final liveStreak = computeStreakFromLogs(
      loggedDates: badgeLoggedDates,
      todayHijri: badgeToday,
      frozenDates: badgeFrozenDates,
    );

    for (final badge in kBadgeDefinitions) {
      if (badge.streakThreshold != null &&
          liveStreak >= badge.streakThreshold!) {
        nextBadges.add(badge.id);
      }
    }

    final recent = await fs.getRecentLogs(user.uid, limit: 7);
    final threshold = (maxScore * 0.8).round();
    final perfectWeek =
        _isPerfectWeekChain(recent) &&
        recent.every((log) => log.score >= threshold);
    if (perfectWeek) nextBadges.add('perfectWeek');

    final weeklyRows = await fs.weeklyLeaderboard();
    final isTopThisWeek =
        weeklyRows.isNotEmpty && weeklyRows.first['uid'] == user.uid;
    if (isTopThisWeek) nextBadges.add('topOfCommunity');

    // Log newly unlocked badges
    final newBadges = nextBadges.difference(user.badges.toSet());
    for (final badgeId in newBadges) {
      AnalyticsService.instance.logBadgeUnlocked(name: badgeId);
    }

    await fs.updateUser(user.uid, <String, dynamic>{
      'badges': nextBadges.toList(),
      'streakFreezeWeekKey': currentWeekKey,
    });

    final displayName = submittedLog.isAnonymousDisplay
        ? 'Anonymous'
        : (submittedLog.displayName.trim().isEmpty
              ? 'Community member'
              : submittedLog.displayName.trim());

    await fs.addActivityFeedItem(
      type: 'completion',
      message: '$displayName completed today\'s amal.',
      uid: user.uid,
    );
    if (resultingCurrentStreak > 0 && resultingCurrentStreak % 7 == 0) {
      await fs.addActivityFeedItem(
        type: 'streak',
        message: '$displayName is on a $resultingCurrentStreak-day streak.',
        uid: user.uid,
      );
    }
  }
}

String _dayOfWeekName(int weekday) {
  switch (weekday) {
    case 1:
      return 'monday';
    case 2:
      return 'tuesday';
    case 3:
      return 'wednesday';
    case 4:
      return 'thursday';
    case 5:
      return 'friday';
    case 6:
      return 'saturday';
    case 7:
      return 'sunday';
    default:
      return 'unknown';
  }
}

String _hijriMonthFromStorage(String hijriDate) {
  final parts = hijriDate.split('-');
  if (parts.length < 2) return 'unknown';
  final monthNum = int.tryParse(parts[1]) ?? 0;
  const months = [
    '',
    'muharram',
    'safar',
    'rabi_ul_awwal',
    'rabi_us_sani',
    'jumada_al_ula',
    'jumada_al_thani',
    'rajab',
    'shaban',
    'ramadan',
    'shawwal',
    'dhul_qadah',
    'dhul_hijjah',
  ];
  return (monthNum >= 1 && monthNum <= 12) ? months[monthNum] : 'unknown';
}
