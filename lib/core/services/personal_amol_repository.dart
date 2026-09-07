import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/personal_amol_model.dart';
import '../../models/personal_amol_streak_model.dart';

/// Firestore data access for personal amol.
///
/// 🔒 Personal amol lives in per-user subcollections under `users/{uid}`:
///   - definitions:  `users/{uid}/personal_amol/{amolId}`
///   - completions:  `users/{uid}/personal_amol_completions/{hijriDate}_{amolId}`
///   - streaks:      `users/{uid}/personal_amol_streaks/{amolId}`
///
/// These subcollections are structurally unreachable by any top-level
/// `amal_logs` / `users` query and must never feed community score, streak, or
/// leaderboard calculations.
class PersonalAmolRepository {
  PersonalAmolRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int _recentLogs = 30;

  CollectionReference<Map<String, dynamic>> _definitions(String uid) =>
      _firestore.collection('users').doc(uid).collection('personal_amol');

  CollectionReference<Map<String, dynamic>> _completions(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('personal_amol_completions');

  DocumentReference<Map<String, dynamic>> _streakDoc(String uid, String amolId) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('personal_amol_streaks')
          .doc(amolId);

  /// Watches active (non-deleted) personal amol definitions, newest first.
  Stream<List<PersonalAmolModel>> watchActiveAmol(String uid) {
    return _definitions(uid)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PersonalAmolModel.fromDoc).toList());
  }

  Future<int> countAllAmol(String uid) async {
    final snap = await _definitions(uid).get();
    return snap.docs.length;
  }

  Future<void> createAmol(String uid, PersonalAmolModel amol) async {
    await _definitions(uid).doc(amol.id).set(amol.toFirestoreMap());
  }

  Future<void> updateAmol(String uid, PersonalAmolModel amol) async {
    await _definitions(uid).doc(amol.id).set(amol.toFirestoreMap());
  }

  /// Soft delete: sets `isActive = false` so the definition disappears from the
  /// home screen, but historical completion records are preserved.
  Future<void> softDeleteAmol(String uid, String amolId) async {
    await _definitions(uid).doc(amolId).update({'isActive': false});
  }

  Future<List<PersonalAmolCompletion>> getCompletionsForDate(
    String uid,
    String hijriDate,
  ) async {
    final snap = await _completions(uid)
        .where('hijriDate', isEqualTo: hijriDate)
        .get();
    return snap.docs.map(PersonalAmolCompletion.fromDoc).toList();
  }

  Future<void> markComplete(String uid, String amolId, String hijriDate) async {
    final docId = '${hijriDate}_$amolId';
    await _completions(uid).doc(docId).set(
      PersonalAmolCompletion(
        amolId: amolId,
        hijriDate: hijriDate,
        completedAt: DateTime.now(),
      ).toFirestoreMap(),
    );
  }

  Future<void> unmarkComplete(String uid, String amolId, String hijriDate) async {
    final docId = '${hijriDate}_$amolId';
    await _completions(uid).doc(docId).delete();
  }

  Future<List<PersonalAmolCompletion>> getCompletionsInRange(
    String uid,
    String startHijri,
    String endHijri,
  ) async {
    try {
      final snap = await _completions(uid)
          .where('hijriDate', isGreaterThanOrEqualTo: startHijri)
          .where('hijriDate', isLessThanOrEqualTo: endHijri)
          .get();
      return snap.docs.map(PersonalAmolCompletion.fromDoc).toList();
    } on FirebaseException catch (e) {
      // Fallback when the composite index is unavailable: fetch all and filter.
      if (e.code != 'failed-precondition' && e.code != 'not-found') rethrow;
      final snap = await _completions(uid).get();
      return snap.docs
          .map(PersonalAmolCompletion.fromDoc)
          .where(
            (c) =>
                c.hijriDate.compareTo(startHijri) >= 0 &&
                c.hijriDate.compareTo(endHijri) <= 0,
          )
          .toList();
    }
  }

  /// Fetches the most recent completions (for streak computation).
  Future<List<PersonalAmolCompletion>> getRecentCompletions(String uid) async {
    final snap = await _completions(uid)
        .orderBy('hijriDate', descending: true)
        .limit(_recentLogs)
        .get();
    return snap.docs.map(PersonalAmolCompletion.fromDoc).toList();
  }

  Future<void> updateStreak(
    String uid,
    String amolId, {
    required int currentStreak,
    required int bestStreak,
  }) async {
    await _streakDoc(uid, amolId).set(
      PersonalStreakResult(
        amolId: amolId,
        currentStreak: currentStreak,
        bestStreak: bestStreak,
      ).toFirestoreMap(),
    );
  }

  Stream<PersonalStreakResult?> watchStreak(String uid, String amolId) {
    return _streakDoc(uid, amolId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return PersonalStreakResult.fromDoc(snap);
    });
  }
}
