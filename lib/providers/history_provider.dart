import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/local_storage_service.dart';
import '../models/amal_log_model.dart';
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
