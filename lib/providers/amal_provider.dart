import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/constants/amal_fields.dart';
import '../core/services/local_storage_service.dart';
import '../core/utils/hijri_helper.dart';
import '../core/utils/streak_helper.dart';
import '../models/amal_log_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';
import 'history_provider.dart';

/// Network status for offline banner (Phase 3).
final connectivityListProvider = StreamProvider<List<ConnectivityResult>>((ref) async* {
  yield await Connectivity().checkConnectivity();
  yield* Connectivity().onConnectivityChanged;
});

class AmalState {
  const AmalState({
    required this.toggles,
    required this.isSubmitted,
    required this.isLoading,
    this.error,
    this.submittedLog,
  });

  factory AmalState.initial() {
    return AmalState(
      toggles: {for (final f in kAmalFields) f.id: false},
      isSubmitted: false,
      isLoading: true,
    );
  }

  final Map<String, bool> toggles;
  final bool isSubmitted;
  final bool isLoading;
  final String? error;
  final AmalLogModel? submittedLog;

  int get doneCount => toggles.values.where((v) => v).length;

  int get totalScore {
    final m = <String, dynamic>{...toggles};
    return calculateScore(m);
  }

  bool get hasAnyDone => toggles.values.any((v) => v);

  AmalState copyWith({
    Map<String, bool>? toggles,
    bool? isSubmitted,
    bool? isLoading,
    String? error,
    AmalLogModel? submittedLog,
    bool clearError = false,
    bool clearSubmittedLog = false,
  }) {
    return AmalState(
      toggles: toggles ?? this.toggles,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      submittedLog: clearSubmittedLog
          ? null
          : (submittedLog ?? this.submittedLog),
    );
  }
}

/// Returned from [AmalNotifier.submit] after a successful local submit (includes streak decision).
class SubmitResult {
  const SubmitResult({
    required this.log,
    required this.streakResult,
  });

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
  }

  final Ref _ref;
  final String _uid;

  String _submittedHiveKey(String hijri) => 'log_${_uid}_$hijri';

  String _draftHiveKey(String hijri) => 'draft_${_uid}_$hijri';

  Future<void> _trySyncSubmittedLog(AmalLogModel log) async {
    try {
      final fs = _ref.read(firestoreServiceProvider);
      await fs.saveAmalLog(log);
      await fs.updateUserLastLogDate(log.uid, log.hijriDate);
    } catch (_) {
      // Keep local cache as source until sync succeeds.
    }
  }

  Future<void> _load() async {
    final hijri = HijriHelper.todayString();
    final fs = _ref.read(firestoreServiceProvider);

    try {
      final fromFs = await fs.getTodayLog(_uid, hijri);
      if (fromFs != null) {
        state = AmalState(
          toggles: Map<String, bool>.from(fromFs.toggles),
          isSubmitted: true,
          isLoading: false,
          submittedLog: fromFs,
        );
        await LocalStorageService.saveLog(
          _submittedHiveKey(hijri),
          fromFs.toHiveMap(),
        );
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
            toggles: Map<String, bool>.from(model.toggles),
            isSubmitted: true,
            isLoading: false,
            submittedLog: model,
          );
          Future<void>.microtask(() => _trySyncSubmittedLog(model));
          return;
        }
      } catch (_) {}
    }

    final draft = LocalStorageService.getLog(_draftHiveKey(hijri));
    if (draft != null && draft['uid'] == _uid) {
      final rawToggles = draft['toggles'];
      if (rawToggles is Map) {
        final next = <String, bool>{
          for (final f in kAmalFields)
            f.id: rawToggles[f.id] as bool? ?? false,
        };
        state = AmalState(
          toggles: next,
          isSubmitted: false,
          isLoading: false,
        );
        return;
      }
    }

    state = AmalState.initial().copyWith(isLoading: false);
  }

  Future<void> _persistDraft() async {
    if (state.isSubmitted) return;
    final hijri = HijriHelper.todayString();
    await LocalStorageService.saveLog(_draftHiveKey(hijri), <String, dynamic>{
      'uid': _uid,
      'hijriDate': hijri,
      'toggles': Map<String, bool>.from(state.toggles),
    });
  }

  void toggle(String fieldId) {
    if (state.isSubmitted || state.isLoading) return;
    if (!kAmalFields.any((f) => f.id == fieldId)) return;
    final next = Map<String, bool>.from(state.toggles);
    next[fieldId] = !(next[fieldId] ?? false);
    state = state.copyWith(toggles: next, clearError: true);
    Future<void>.microtask(_persistDraft);
  }

  void markAllDone() {
    if (state.isSubmitted || state.isLoading) return;
    final next = <String, bool>{for (final f in kAmalFields) f.id: true};
    state = state.copyWith(toggles: next, clearError: true);
    Future<void>.microtask(_persistDraft);
  }

  /// Persists freeze choice after S-16 — keeps streak, marks freeze used for the week.
  Future<void> applyFreeze(UserModel user) async {
    final fs = _ref.read(firestoreServiceProvider);
    await fs.updateStreak(user.uid, streakFreezeUsed: true);
  }

  /// User declined freeze — streak restarts at 1 ([lastLogDate] already set on submit).
  Future<void> resetStreak(String uid) async {
    final fs = _ref.read(firestoreServiceProvider);
    await fs.updateStreak(uid, currentStreak: 1);
  }

  /// Returns the saved log + streak outcome for navigation / S-16, or null on validation / failure.
  Future<SubmitResult?> submit(UserModel user) async {
    if (state.isSubmitted || state.isLoading) return null;
    if (!state.hasAnyDone) {
      state = state.copyWith(error: 'Toggle at least one amal before submitting.');
      return null;
    }

    final hijri = HijriHelper.todayString();
    final toggles = Map<String, bool>.from(state.toggles);
    final score = calculateScore(toggles);
    final now = DateTime.now().toUtc();

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
      streakFreezeUsed: user.streakFreezeUsed,
    );

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final fs = _ref.read(firestoreServiceProvider);
      await fs.saveAmalLog(log);
      try {
        switch (streakResult.action) {
          case StreakAction.increment:
          case StreakAction.reset:
            await fs.updateStreak(
              user.uid,
              currentStreak: streakResult.newCurrentStreak,
              bestStreak: streakResult.newBestStreak,
              lastLogDate: hijri,
            );
            break;
          case StreakAction.showFreeze:
            await fs.updateStreak(user.uid, lastLogDate: hijri);
            break;
        }
      } catch (_) {
        // Streak fields can sync later; log doc is saved.
      }
    } catch (_) {
      // Offline or write failure: cache locally; Firestore will sync when possible.
    } finally {
      await LocalStorageService.saveLog(_submittedHiveKey(hijri), log.toHiveMap());
      await LocalStorageService.deleteLog(_draftHiveKey(hijri));

      state = AmalState(
        toggles: toggles,
        isSubmitted: true,
        isLoading: false,
        submittedLog: log,
      );
    }
    _ref.invalidate(historyMonthProvider);
    Future<void>.microtask(() => _trySyncSubmittedLog(log));
    return SubmitResult(log: log, streakResult: streakResult);
  }
}
