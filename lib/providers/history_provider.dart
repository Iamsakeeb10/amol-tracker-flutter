import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../core/services/islamic_date_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/utils/amal_edit_debug.dart';
import '../core/utils/history_month_calculator.dart';
import '../core/utils/score_calculator.dart';
import '../core/utils/streak_helper.dart';
import '../core/constants/default_amal_fields.dart';
import '../models/amal_log_model.dart';
import '../models/user_model.dart';
import 'amal_fields_provider.dart';
import 'auth_provider.dart';

class HistoryMonthKey {
  const HistoryMonthKey({
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
      other is HistoryMonthKey &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          hijriYear == other.hijriYear &&
          hijriMonth == other.hijriMonth;

  @override
  int get hashCode => Object.hash(uid, hijriYear, hijriMonth);
}

class AmalLogRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Bumped after amal edit/backfill so dependent providers and screens refetch.
final amalLogRefreshProvider =
    NotifierProvider<AmalLogRefreshNotifier, int>(AmalLogRefreshNotifier.new);

/// Monthly amal logs for the history calendar (S-04).
final historyMonthProvider =
    FutureProvider.autoDispose.family<List<AmalLogModel>, HistoryMonthKey>((
  ref,
  key,
) async {
  final fs = ref.read(firestoreServiceProvider);
  return fs.getMonthLogs(key.uid, key.hijriYear, key.hijriMonth);
});

class HistoryMonthSummaryInput {
  const HistoryMonthSummaryInput({
    required this.monthKey,
    required this.accountCreatedAt,
    required this.locale,
  });

  final HistoryMonthKey monthKey;
  final DateTime accountCreatedAt;
  final String locale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryMonthSummaryInput &&
          monthKey == other.monthKey &&
          accountCreatedAt == other.accountCreatedAt &&
          locale == other.locale;

  @override
  int get hashCode => Object.hash(monthKey, accountCreatedAt, locale);
}

/// Pre-computed calendar days and month stats for history screen.
final historyMonthSummaryProvider =
    Provider.autoDispose.family<AsyncValue<HistoryMonthSummary>, HistoryMonthSummaryInput>((
  ref,
  input,
) {
  final logsAsync = ref.watch(historyMonthProvider(input.monthKey));
  final fields = ref.watch(amalFieldsListProvider);
  final maxScore =
      getMaxScore(fields).clamp(1, kDefaultMaxDailyScore);
  final todayStr = IslamicDateService.getCurrentIslamicDateStringSafe();
  final accountCreatedHijri =
      IslamicDateService.hijriStorageForAccountCreated(input.accountCreatedAt);
  final daysInMonth = HijriCalendar().getDaysInMonth(
    input.monthKey.hijriYear,
    input.monthKey.hijriMonth,
  );

  return logsAsync.when(
    data: (logs) => AsyncData(
      HistoryMonthCalculator.compute(
        logs: logs,
        fields: fields,
        hijriYear: input.monthKey.hijriYear,
        hijriMonth: input.monthKey.hijriMonth,
        todayStr: todayStr,
        accountCreatedHijri: accountCreatedHijri,
        daysInMonth: daysInMonth,
        maxScore: maxScore,
        locale: input.locale,
      ),
    ),
    loading: () => const AsyncLoading(),
    error: (error, stack) => AsyncError(error, stack),
  );
});

class DayLogKey {
  const DayLogKey({required this.uid, required this.hijriDate});

  final String uid;
  final String hijriDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayLogKey &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          hijriDate == other.hijriDate;

  @override
  int get hashCode => Object.hash(uid, hijriDate);
}

/// Log for S-13 — Firestore first, then Hive submitted cache.
final dayDetailLogProvider =
    FutureProvider.autoDispose.family<AmalLogModel?, DayLogKey>((ref, key) async {
  final fs = ref.read(firestoreServiceProvider);
  try {
    final log = await fs.getLog(key.uid, key.hijriDate);
    if (log != null) return log;
  } catch (_) {}
  final hiveKey = 'log_${key.uid}_${key.hijriDate}';
  final cached = LocalStorageService.getLog(hiveKey);
  if (cached != null) {
    try {
      final model = AmalLogModel.fromHiveMap(cached);
      if (model.uid == key.uid && model.hijriDate == key.hijriDate) {
        return model;
      }
    } catch (_) {}
  }
  return null;
});

/// Whether a Hijri day can be opened in the editor (with or without a log).
class EditableDayState {
  const EditableDayState({
    required this.canEdit,
    this.existingLog,
    this.isTodayNotSubmitted = false,
  });

  final bool canEdit;
  final AmalLogModel? existingLog;

  /// True when viewing today before the user has submitted from Home.
  final bool isTodayNotSubmitted;
}

AmalLogModel? _logFromHive(String uid, String hijriDate) {
  final cached = LocalStorageService.getLog('log_${uid}_$hijriDate');
  if (cached == null) return null;
  try {
    final model = AmalLogModel.fromHiveMap(cached);
    if (model.uid == uid && model.hijriDate == hijriDate) return model;
  } catch (_) {}
  return null;
}

/// Hijri day edit eligibility since account creation. Log optional (backfill).
final editableDayProvider =
    FutureProvider.autoDispose.family<EditableDayState, String>((
  ref,
  hijriDate,
) async {
  const denied = EditableDayState(canEdit: false);

  final auth = ref.watch(authStateProvider).asData?.value;
  if (auth == null) {
    logAmalEditDebug('hijriDate=$hijriDate deny=not_signed_in');
    return denied;
  }

  UserModel? user;
  try {
    user = await ref.watch(currentUserProvider.future);
  } catch (e) {
    logAmalEditDebug('hijriDate=$hijriDate deny=user_load_error $e');
    return denied;
  }
  if (user == null) {
    logAmalEditDebug('hijriDate=$hijriDate deny=no_user_profile');
    return denied;
  }

  final today = IslamicDateService.getCurrentIslamicDateStringSafe();
  logAmalEditDebug('hijriDate=$hijriDate today=$today');

  if (hijriDate.compareTo(today) > 0) {
    logAmalEditDebug('hijriDate=$hijriDate deny=future_date');
    return denied;
  }

  final accountCreatedHijri =
      IslamicDateService.hijriStorageForAccountCreated(user.createdAt);
  if (hijriDate.compareTo(accountCreatedHijri) < 0) {
    logAmalEditDebug(
      'hijriDate=$hijriDate deny=before_account '
      'accountHijri=$accountCreatedHijri',
    );
    return denied;
  }

  final fs = ref.read(firestoreServiceProvider);
  AmalLogModel? log;
  try {
    log = await fs.getLog(user.uid, hijriDate);
  } catch (e) {
    logAmalEditDebug('hijriDate=$hijriDate firestore_error=$e');
  }
  log ??= _logFromHive(user.uid, hijriDate);

  if (hijriDate == today && log == null) {
    logAmalEditDebug('hijriDate=$hijriDate deny=today_not_submitted');
    return const EditableDayState(
      canEdit: false,
      isTodayNotSubmitted: true,
    );
  }

  logAmalEditDebug(
    'hijriDate=$hijriDate allow_edit hasLog=${log != null} '
    'score=${log?.score ?? 0}',
  );
  return EditableDayState(canEdit: true, existingLog: log);
});

/// Authoritative streak computed from actual logs, not the potentially stale
/// Firestore `currentStreak` field. Fetches the last 30 days of logs and
/// counts consecutive completed days backwards from today.
///
/// Excludes backfilled logs (submitted on a different Hijri day) so the
/// streak only counts genuine daily completions.
final liveStreakProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return 0;

  // Refetch when logs change (after submit, edit, etc.).
  ref.watch(amalLogRefreshProvider);

  final fs = ref.read(firestoreServiceProvider);
  final logs = await fs.getRecentLogs(user.uid, limit: 30);

  final today = IslamicDateService.getCurrentIslamicDateStringSafe();
  final loggedDates = <String>{
    for (final log in logs)
      if (!isBackfilledLog(log)) log.hijriDate,
  };

  final frozenDates = <String>{
    if (user.streakFreezeDate.isNotEmpty) user.streakFreezeDate,
  };

  return computeStreakFromLogs(
    loggedDates: loggedDates,
    todayHijri: today,
    frozenDates: frozenDates,
  );
});
