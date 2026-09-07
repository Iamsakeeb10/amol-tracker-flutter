import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/personal_amol_model.dart';
import '../../models/personal_amol_streak_model.dart';

/// Firestore data access for personal amol.
///
/// 🔒 Personal amol lives in per-user subcollections under `users/{uid}`:
///   - definitions:  `users/{uid}/personal_amol/{amolId}`
///   - completions:  `users/{uid}/personal_amol_completions/{hijriDate}_{amolId}`
///     (toggle) or `{hijriDate}_{amolId}_{timestamp}` (count increments)
///   - streaks:      `users/{uid}/personal_amol_streaks/{amolId}`
///
/// These subcollections are structurally unreachable by any top-level
/// `amal_logs` / `users` query and must never feed community score, streak, or
/// leaderboard calculations.
class PersonalAmolRepository {
  PersonalAmolRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Minimum distinct Hijri dates a streak computation may rely on.
  static const int _streakLookbackDistinctDays = 30;
  static const int _streakLookbackBatch = 100;
  static const int _streakLookbackMaxPages = 50;

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

  /// Watches all personal amol definitions (active and soft-deleted), newest
  /// first. The history calendar uses this so past completions of deleted amols
  /// still fill the calendar.
  Stream<List<PersonalAmolModel>> watchAllAmol(String uid) {
    return _definitions(uid)
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

  /// Snapshot stream of a day's completions. Because Firestore emits a local
  /// snapshot immediately when a write lands in the local cache (before the
  /// server round-trip finishes), the home tile count updates instantly on
  /// +/- taps instead of waiting on the network.
  Stream<List<PersonalAmolCompletion>> watchCompletionsForDate(
    String uid,
    String hijriDate,
  ) {
    return _completions(uid)
        .where('hijriDate', isEqualTo: hijriDate)
        .snapshots()
        .map((snap) => snap.docs.map(PersonalAmolCompletion.fromDoc).toList());
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

  /// Adds one counted completion (not idempotent): count-type amols create one
  /// document per increment so "done today" = documents count >= target.
  Future<void> incrementCompletion(
    String uid,
    String amolId,
    String hijriDate,
  ) async {
    final docId =
        '${hijriDate}_${amolId}_${DateTime.now().microsecondsSinceEpoch}';
    await _completions(uid).doc(docId).set(
      PersonalAmolCompletion(
        amolId: amolId,
        hijriDate: hijriDate,
        completedAt: DateTime.now(),
      ).toFirestoreMap(),
    );
  }

  /// Removes the most recent counted completion for the given amol/date.
  Future<void> decrementCompletion(
    String uid,
    String amolId,
    String hijriDate,
  ) async {
    final snap = await _completions(uid)
        .where('hijriDate', isEqualTo: hijriDate)
        .get();
    final docs = snap.docs.where((d) => d['amolId'] == amolId).toList()
      ..sort((a, b) {
        final ta = _completedAt(a);
        final tb = _completedAt(b);
        return tb.compareTo(ta);
      });
    if (docs.isEmpty) return;
    await _completions(uid).doc(docs.first.id).delete();
  }

  static DateTime _completedAt(DocumentSnapshot<Map<String, dynamic>> doc) {
    final raw = doc.data()?['completedAt'];
    if (raw is Timestamp) return raw.toDate();
    final parsed = DateTime.tryParse('$raw');
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Applies a net completion delta for [hijriDate] in one Firestore batch.
  /// This is the save-time counterpart of the staged home edits: positive
  /// [delta] writes that many count docs (or the single toggle doc), negative
  /// [delta] deletes the most recent [delta] docs for the amol/date.
  Future<void> applyCompletionDelta(
    String uid,
    String amolId,
    String hijriDate,
    int delta, {
    required bool isToggle,
  }) async {
    if (delta == 0) return;
    if (delta > 0) {
      if (isToggle) {
        // A toggle day is a single on/off doc; never more than one.
        await _completions(uid).doc('${hijriDate}_$amolId').set(
          PersonalAmolCompletion(
            amolId: amolId,
            hijriDate: hijriDate,
            completedAt: DateTime.now(),
          ).toFirestoreMap(),
        );
        return;
      }
      final batch = _firestore.batch();
      final nowMicros = DateTime.now().microsecondsSinceEpoch;
      for (var i = 0; i < delta; i++) {
        final docId =
            '${hijriDate}_${amolId}_${nowMicros}_$i';
        batch.set(
          _completions(uid).doc(docId),
          PersonalAmolCompletion(
            amolId: amolId,
            hijriDate: hijriDate,
            completedAt: DateTime.now(),
          ).toFirestoreMap(),
        );
      }
      await batch.commit();
      return;
    }
    // delta < 0: delete the |delta| most-recent completions for the amol/date.
    final snap = await _completions(uid)
        .where('hijriDate', isEqualTo: hijriDate)
        .get();
    final docs = snap.docs.where((d) => d['amolId'] == amolId).toList()
      ..sort((a, b) {
        final ta = _completedAt(a);
        final tb = _completedAt(b);
        return tb.compareTo(ta);
      });
    if (docs.isEmpty) return;
    final toRemove = docs.take(delta.abs()).toList();
    final batch = _firestore.batch();
    for (final doc in toRemove) {
      batch.delete(_completions(uid).doc(doc.id));
    }
    await batch.commit();
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

  /// Fetches recent completions across all of the user's personal amols, for
  /// streak computation. Count-type amols write one document per increment, so
  /// a plain `limit(n)` would only cover a few days and truncate streaks.
  /// Instead, paginates (no extra composite index needed) until at least
  /// [_streakLookbackDistinctDays] distinct Hijri dates have been collected,
  /// or the collection is exhausted. Bounded by [_streakLookbackMaxPages]
  /// batches to guard against pathological single-day volumes.
  Future<List<PersonalAmolCompletion>> getRecentCompletions(String uid) async {
    final out = <PersonalAmolCompletion>[];
    final distinctDates = <String>{};
    DocumentSnapshot<Map<String, dynamic>>? last;
    for (var page = 0; page < _streakLookbackMaxPages; page++) {
      var query = _completions(uid).orderBy('hijriDate', descending: true);
      final batch = last == null
          ? await query.limit(_streakLookbackBatch).get()
          : await query
              .startAfterDocument(last)
              .limit(_streakLookbackBatch)
              .get();
      if (batch.docs.isEmpty) break;
      for (final doc in batch.docs) {
        final c = PersonalAmolCompletion.fromDoc(doc);
        out.add(c);
        distinctDates.add(c.hijriDate);
      }
      last = batch.docs.last;
      if (distinctDates.length >= _streakLookbackDistinctDays) break;
    }
    return out;
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
