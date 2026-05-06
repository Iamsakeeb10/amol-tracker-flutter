import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../models/amal_log_model.dart';
import '../../models/user_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _amalLogs =>
      _firestore.collection('amal_logs');

  Future<bool> userExists(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists;
  }

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await _users.doc(uid).update(fields);
  }

  Stream<UserModel?> userStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDoc(doc);
    });
  }

  /// Submitted log for [hijriDate] (`YYYY-MM-DD`), or null if none.
  Future<AmalLogModel?> getTodayLog(String uid, String hijriDate) async {
    final docId = '${uid}_$hijriDate';
    final snap = await _amalLogs.doc(docId).get();
    if (!snap.exists) return null;
    return AmalLogModel.fromDoc(snap);
  }

  /// Alias for [getTodayLog] — any Hijri day, not only "today".
  Future<AmalLogModel?> getLog(String uid, String hijriDate) =>
      getTodayLog(uid, hijriDate);

  /// All of the user's submitted logs in a given Hijri month.
  Future<List<AmalLogModel>> getMonthLogs(
    String uid,
    int hijriYear,
    int hijriMonth,
  ) async {
    final cal = HijriCalendar();
    final daysInMonth = cal.getDaysInMonth(hijriYear, hijriMonth);
    final mm = hijriMonth.toString().padLeft(2, '0');
    final start = '$hijriYear-$mm-01';
    final end =
        '$hijriYear-$mm-${daysInMonth.toString().padLeft(2, '0')}';

    try {
      final query = await _amalLogs
          .where('uid', isEqualTo: uid)
          .where('hijriDate', isGreaterThanOrEqualTo: start)
          .where('hijriDate', isLessThanOrEqualTo: end)
          .get();

      final logs = query.docs.map(AmalLogModel.fromDoc).toList()
        ..sort((a, b) => a.hijriDate.compareTo(b.hijriDate));
      return logs;
    } on FirebaseException {
      // Fallback when composite index is missing:
      // fetch by uid and filter month client-side.
      final query = await _amalLogs.where('uid', isEqualTo: uid).get();
      final logs = query.docs
          .map(AmalLogModel.fromDoc)
          .where((log) => log.hijriDate.compareTo(start) >= 0 && log.hijriDate.compareTo(end) <= 0)
          .toList()
        ..sort((a, b) => a.hijriDate.compareTo(b.hijriDate));
      return logs;
    }
  }

  /// Updates streak-related fields on `users/{uid}` (only sends non-null keys).
  Future<void> updateStreak(
    String uid, {
    int? currentStreak,
    int? bestStreak,
    bool? streakFreezeUsed,
    String? lastLogDate,
  }) async {
    final fields = <String, dynamic>{};
    if (currentStreak != null) fields['currentStreak'] = currentStreak;
    if (bestStreak != null) fields['bestStreak'] = bestStreak;
    if (streakFreezeUsed != null) {
      fields['streakFreezeUsed'] = streakFreezeUsed;
    }
    if (lastLogDate != null) fields['lastLogDate'] = lastLogDate;
    if (fields.isEmpty) return;
    await _users.doc(uid).update(fields);
  }

  Future<void> saveAmalLog(AmalLogModel log) async {
    await _amalLogs.doc(log.docId).set(log.toFirestoreMap());
  }

  /// Updates [lastLogDate] (Hijri `YYYY-MM-DD`) after a successful submit.
  Future<void> updateUserLastLogDate(String uid, String hijriDate) async {
    await _users.doc(uid).update(<String, dynamic>{'lastLogDate': hijriDate});
  }
}
