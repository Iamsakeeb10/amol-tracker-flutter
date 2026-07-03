import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/constants/amal_fields.dart';
import '../core/constants/default_amal_fields.dart';
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

int _streakAfterFreeze(int currentStreak) {
  final baseline = currentStreak <= 0 ? 1 : currentStreak;
  return baseline + 1;
}

class AmalState {
  const AmalState({
    required this.toggles,
    required this.fields,
    required this.isSubmitted,
    required this.isLoading,
    this.error,
    this.submittedLog,
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
    state = state.copyWith(
      toggles: normalizeTogglesForFields(state.toggles, fields),
      fields: fields,
      clearError: true,
    );
  }

  String _submittedHiveKey(String hijri) => 'log_${_uid}_$hijri';

  String _draftHiveKey(String hijri) => 'draft_${_uid}_$hijri';

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
        state = AmalState(
          toggles: normalizeTogglesForFields(fromFs.toggles, fields),
          fields: fields,
          isSubmitted: true,
          isLoading: false,
          submittedLog: fromFs,
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
          state = AmalState(
            toggles: normalizeTogglesForFields(model.toggles, fields),
            fields: fields,
            isSubmitted: true,
            isLoading: false,
            submittedLog: model,
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
        state = AmalState(
          toggles: next,
          fields: fields,
          isSubmitted: false,
          isLoading: false,
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

      final user = _ref.read(currentUserProvider).asData?.value;
      var streak = streakOverride ?? user?.currentStreak ?? 0;
      if (streakOverride == null && state.isSubmitted) {
        streak = resolveDisplayedStreakValues(
          currentStreak: streak,
          bestStreak: user?.bestStreak ?? streak,
          hasSubmittedToday: true,
        ).currentStreak;
      }

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
    state = state.copyWith(toggles: next, clearError: true);
    Future<void>.microtask(_persistDraft);
  }

  void markAllDone() {
    if (state.isSubmitted || state.isLoading) return;
    final activeFields = resolveAmalFields(state.fields);
    final next = Map<String, dynamic>.from(state.toggles);
    for (final f in activeFields) {
      next[f.id] = f.type == AmalType.numeric ? f.maxValue : true;
    }
    state = state.copyWith(toggles: next, clearError: true);
    Future<void>.microtask(_persistDraft);
  }

  void clearAll() {
    if (state.isSubmitted || state.isLoading) return;
    state = state.copyWith(
      toggles: _emptyTogglesForFields(state.fields),
      clearError: true,
    );
    Future<void>.microtask(_persistDraft);
  }

  Future<void> applyFreeze(UserModel user, {required String hijri}) async {
    final fs = _ref.read(firestoreServiceProvider);
    final baseline = user.currentStreak <= 0 ? 1 : user.currentStreak;
    final newCurrent = baseline + 1;
    final newBest = newCurrent > user.bestStreak ? newCurrent : user.bestStreak;
    await fs.updateStreak(
      user.uid,
      streakFreezeUsed: true,
      streakFreezeWeekKey: weekKeyFromDate(HijriHelper.bangladeshNow()),
      currentStreak: newCurrent,
      bestStreak: newBest,
      lastLogDate: hijri,
    );
  }

  Future<void> resetStreak(String uid) async {
    final fs = _ref.read(firestoreServiceProvider);
    await fs.updateStreak(uid, currentStreak: 1);
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
    );

    final streakResult = computeStreakResult(
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
      // Ensure lastLogDate is always updated when the log is saved,
      // even if the full updateStreak call fails.
      unawaited(fs.updateUserLastLogDate(user.uid, hijri).catchError((_) {}));
      try {
        switch (streakResult.action) {
          case StreakAction.increment:
          case StreakAction.reset:
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
              resultingCurrentStreak: _streakAfterFreeze(user.currentStreak),
              currentWeekKey: currentWeekKey,
            );
            break;
        }
      } catch (e) {
        // Streak fields can sync later; log doc is saved.
      }
    } catch (_) {
      submitWarning = 'Saved locally - will sync when back online.';
    } finally {
      await LocalStorageService.saveLog(
        _submittedHiveKey(hijri),
        log.toHiveMap(),
      );
      await LocalStorageService.deleteLog(_draftHiveKey(hijri));

      state = AmalState(
        toggles: toggles,
        fields: state.fields,
        isSubmitted: true,
        isLoading: false,
        error: submitWarning,
        submittedLog: log,
      );
      await _updateHomeWidget(
        streakOverride: streakResult.action == StreakAction.showFreeze
            ? _streakAfterFreeze(user.currentStreak)
            : streakResult.newCurrentStreak,
      );
    }
    _ref.invalidate(historyMonthProvider);
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

    for (final badge in kBadgeDefinitions) {
      if (badge.streakThreshold != null &&
          resultingCurrentStreak >= badge.streakThreshold!) {
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
