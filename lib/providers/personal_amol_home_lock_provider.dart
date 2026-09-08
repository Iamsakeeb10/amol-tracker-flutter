import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/services/islamic_date_service.dart';
import '../core/services/local_storage_service.dart';
import 'date_provider.dart';

/// Hive key for the Hijri day on which personal amol was saved on home.
String personalAmolHomeLockKey(String uid) => 'personal_amol_home_locked_$uid';

/// Bumps when the home lock is marked or unlocked so listeners rebuild.
final personalAmolHomeLockRevisionProvider =
    StateNotifierProvider.family<_PersonalAmolHomeLockRevision, int, String>(
  (ref, uid) => _PersonalAmolHomeLockRevision(),
);

class _PersonalAmolHomeLockRevision extends StateNotifier<int> {
  _PersonalAmolHomeLockRevision() : super(0);

  void bump() => state++;
}

/// True when personal amol tiles on home should be read-only for [uid] today.
///
/// Independent of community `isSubmitted`. Persisted as today's Hijri string
/// under [personalAmolHomeLockKey].
final personalAmolHomeLockedProvider = Provider.family<bool, String>((ref, uid) {
  ref.watch(personalAmolHomeLockRevisionProvider(uid));
  final today = ref.watch(currentHijriDateProvider);
  final stored = LocalStorageService.getPref<String?>(
    personalAmolHomeLockKey(uid),
    null,
  );
  if (stored == null) return false;
  if (stored != today) {
    // Stale lock from a previous Islamic day — clear and treat as unlocked.
    unawaited(LocalStorageService.deletePref(personalAmolHomeLockKey(uid)));
    return false;
  }
  return true;
});

void _bumpLockRevision(dynamic ref, String uid) {
  ref.read(personalAmolHomeLockRevisionProvider(uid).notifier).bump();
}

/// Marks personal amol as saved/locked for [hijriDate] (normally today).
Future<void> markPersonalAmolHomeLocked(
  dynamic ref, {
  required String uid,
  required String hijriDate,
}) async {
  await LocalStorageService.setPref(personalAmolHomeLockKey(uid), hijriDate);
  _bumpLockRevision(ref, uid);
}

/// Convenience when the caller already knows "today".
Future<void> markPersonalAmolHomeLockedToday(dynamic ref, String uid) async {
  final today = IslamicDateService.getCurrentIslamicDateStringSafe();
  await markPersonalAmolHomeLocked(ref, uid: uid, hijriDate: today);
}

/// Clears the home lock so personal tiles become editable again.
Future<void> unlockPersonalAmolHome(dynamic ref, String uid) async {
  await LocalStorageService.deletePref(personalAmolHomeLockKey(uid));
  _bumpLockRevision(ref, uid);
}

/// Drops a stale lock when the Islamic day rolls over.
Future<void> clearPersonalAmolHomeLockIfStale(String uid, String today) async {
  final stored = LocalStorageService.getPref<String?>(
    personalAmolHomeLockKey(uid),
    null,
  );
  if (stored != null && stored != today) {
    await LocalStorageService.deletePref(personalAmolHomeLockKey(uid));
  }
}
