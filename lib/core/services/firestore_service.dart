import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../models/activity_feed_item_model.dart';
import '../../models/amal_log_model.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _amalLogs =>
      _firestore.collection('amal_logs');

  static const int _communityPageSize = 20;
  static const int _activityFeedPageSize = 25;

  CollectionReference<Map<String, dynamic>> get _activityFeed =>
      _firestore.collection('activity_feed');

  CollectionReference<Map<String, dynamic>> _notificationItems(String uid) {
    return _firestore.collection('notifications').doc(uid).collection('items');
  }

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
    final end = '$hijriYear-$mm-${daysInMonth.toString().padLeft(2, '0')}';

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
      final logs =
          query.docs
              .map(AmalLogModel.fromDoc)
              .where(
                (log) =>
                    log.hijriDate.compareTo(start) >= 0 &&
                    log.hijriDate.compareTo(end) <= 0,
              )
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

  /// Real-time stream of submitted logs for a Hijri day, sorted by score.
  Stream<List<AmalLogModel>> communityDayStream(String hijriDate) {
    return _amalLogs.where('hijriDate', isEqualTo: hijriDate).snapshots().map((
      snap,
    ) {
      final rows = snap.docs.map(AmalLogModel.fromDoc).toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      if (rows.length <= _communityPageSize) return rows;
      return rows.take(_communityPageSize).toList();
    });
  }

  /// One-time paginated fetch of submitted logs for a Hijri day.
  Future<
    ({List<AmalLogModel> rows, DocumentSnapshot<Map<String, dynamic>>? lastDoc})
  >
  communityDayFetch(
    String hijriDate, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    try {
      var query = _amalLogs
          .where('hijriDate', isEqualTo: hijriDate)
          .orderBy('score', descending: true)
          .limit(_communityPageSize);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final snap = await query.get();
      final rows = snap.docs.map(AmalLogModel.fromDoc).toList();
      final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      return (rows: rows, lastDoc: lastDoc);
    } on FirebaseException {
      // Index fallback: query by date only, sort client-side, then paginate locally.
      final snap = await _amalLogs
          .where('hijriDate', isEqualTo: hijriDate)
          .get();
      final docs = snap.docs.toList()
        ..sort((a, b) {
          final aScore = (a.data()['score'] as num?)?.toInt() ?? 0;
          final bScore = (b.data()['score'] as num?)?.toInt() ?? 0;
          return bScore.compareTo(aScore);
        });

      var start = 0;
      if (startAfter != null) {
        final idx = docs.indexWhere((d) => d.id == startAfter.id);
        if (idx >= 0) start = idx + 1;
      }
      final end = (start + _communityPageSize).clamp(0, docs.length);
      final pageDocs = docs.sublist(start, end);
      final rows = pageDocs.map(AmalLogModel.fromDoc).toList();
      final lastDoc = pageDocs.isNotEmpty ? pageDocs.last : null;
      return (rows: rows, lastDoc: lastDoc);
    }
  }

  /// Real-time activity feed in reverse chronological order.
  Stream<List<ActivityFeedItemModel>> activityFeedStream() {
    return _activityFeed
        .orderBy('createdAt', descending: true)
        .limit(_activityFeedPageSize)
        .snapshots()
        .map((snap) => snap.docs.map(ActivityFeedItemModel.fromDoc).toList());
  }

  Future<List<AmalLogModel>> getRecentLogs(String uid, {int limit = 7}) async {
    try {
      final query = await _amalLogs
          .where('uid', isEqualTo: uid)
          .orderBy('hijriDate', descending: true)
          .limit(limit)
          .get();
      final rows = query.docs.map(AmalLogModel.fromDoc).toList()
        ..sort((a, b) => a.hijriDate.compareTo(b.hijriDate));
      return rows;
    } on FirebaseException {
      // Composite-index fallback for uid + orderBy(hijriDate).
      final query = await _amalLogs.where('uid', isEqualTo: uid).get();
      final rows = query.docs.map(AmalLogModel.fromDoc).toList()
        ..sort((a, b) => a.hijriDate.compareTo(b.hijriDate));
      if (rows.length <= limit) return rows;
      return rows.sublist(rows.length - limit);
    }
  }

  Future<bool> hasSentDuaToday({
    required String senderUid,
    required String recipientUid,
    required String hijriDate,
  }) async {
    final query = await _notificationItems(recipientUid)
        .where('type', isEqualTo: 'dua')
        .where('senderUid', isEqualTo: senderUid)
        .where('hijriDate', isEqualTo: hijriDate)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> sendDua({
    required String senderUid,
    required String recipientUid,
    required String message,
    required String hijriDate,
  }) async {
    await _notificationItems(recipientUid).add(<String, dynamic>{
      'type': 'dua',
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'senderUid': senderUid,
      'hijriDate': hijriDate,
    });
  }

  Stream<List<NotificationModel>> notificationStream(String uid) {
    return _notificationItems(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromDoc).toList());
  }

  Future<void> markNotificationRead(String uid, String notificationId) async {
    await _notificationItems(
      uid,
    ).doc(notificationId).update(<String, dynamic>{'isRead': true});
  }

  Future<void> markAllNotificationsRead(String uid) async {
    final unread = await _notificationItems(
      uid,
    ).where('isRead', isEqualTo: false).get();
    if (unread.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, <String, dynamic>{'isRead': true});
    }
    await batch.commit();
  }
}
