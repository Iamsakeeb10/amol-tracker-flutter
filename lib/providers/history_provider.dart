import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/islamic_date_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/utils/amal_edit_debug.dart';
import '../models/amal_log_model.dart';
import '../models/user_model.dart';
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

/// Whether a past Hijri day can be opened in the editor (with or without a log).
class EditableDayState {
  const EditableDayState({required this.canEdit, this.existingLog});

  final bool canEdit;
  final AmalLogModel? existingLog;
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

/// Past Hijri day within 6-day BD window (excludes today). Log optional (backfill).
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

  final bdNow = IslamicDateService.nowInBD();
  final today = IslamicDateService.getCurrentIslamicDateStringSafe();
  final editableDays =
      IslamicDateService.editableHijriStoragesBeforeToday(today);

  logAmalEditDebug(
    'hijriDate=$hijriDate today=$today bdNow=$bdNow '
    'editableWindow=$editableDays',
  );

  if (hijriDate == today) {
    logAmalEditDebug('hijriDate=$hijriDate deny=is_today_use_home');
    return denied;
  }
  if (!IslamicDateService.isWithinEditWindow(hijriDate, today, 6)) {
    logAmalEditDebug('hijriDate=$hijriDate deny=outside_6_hijri_days');
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

  logAmalEditDebug(
    'hijriDate=$hijriDate allow_edit hasLog=${log != null} '
    'score=${log?.score ?? 0}',
  );
  return EditableDayState(canEdit: true, existingLog: log);
});
