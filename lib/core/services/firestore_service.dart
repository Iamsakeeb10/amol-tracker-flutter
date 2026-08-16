import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hijri/hijri_calendar.dart';

import 'dua_push_gateway_service.dart';
import 'islamic_date_service.dart';
import '../utils/dua_push_debug.dart';
import '../constants/amal_fields.dart';
import '../../models/activity_feed_item_model.dart';
import '../../models/amal_log_model.dart';
import '../../models/announcement_model.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../models/app_config_model.dart';

class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    DuaPushGatewayService? duaPushGateway,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _duaPushGateway =
           duaPushGateway ?? DuaPushGatewayService.fromEnvironment();

  final FirebaseFirestore _firestore;
  final DuaPushGatewayService _duaPushGateway;

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

  Future<UserModel?> fetchUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await _users.doc(uid).update(fields);
  }

  Future<void> deleteUserDoc(String uid) async {
    await _users.doc(uid).delete();
  }

  Future<int> getLifetimeAmolLogsCount(String uid) async {
    if (uid.isEmpty) return 0;
    try {
      final aggregateQuery = await _amalLogs.where('uid', isEqualTo: uid).count().get();
      return aggregateQuery.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> updateUserReviewMilestone(String uid, int milestone) async {
    if (uid.isEmpty) return;
    await _users.doc(uid).update(<String, dynamic>{
      'lastReviewPromptMilestone': milestone,
    });
  }

  Future<void> markBadgeCelebrationsSeen(
    String uid,
    List<String> badgeIds,
  ) async {
    if (badgeIds.isEmpty) return;
    await _users.doc(uid).update(<String, dynamic>{
      'seenBadgeCelebrations': FieldValue.arrayUnion(badgeIds),
    });
  }

  /*
  Purpose:
  Stream active admin announcements for real-time modal display on HomeScreen.

  Response:
  Emits a list of currently active announcements ordered newest first.

  Business Rules:
  - Only documents with isActive == true are queried.
  - Client-side isCurrentlyActive filters startsAt / expiresAt windows.
  - Empty list when collection is missing or has no active docs.

  Flow:
  1. Subscribe to announcements where isActive is true.
  2. Order by createdAt descending.
  3. Map docs to AnnouncementModel and filter by isCurrentlyActive.

  Side Effects:
  - Opens a live Firestore listener.

  Failure Cases:
  - Stream errors propagate to Riverpod; UI treats as no pending announcement.
  */
  Stream<List<AnnouncementModel>> announcementsStream() {
    return _resilientAnnouncementStream(
      query: () => _announcements
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true),
      mapDocs: (docs) => docs
          .map(AnnouncementModel.fromDoc)
          .where((announcement) => announcement.isCurrentlyActive)
          .toList(),
      fallbackMapDocs: (docs) {
        final items = docs
            .map(AnnouncementModel.fromDoc)
            .where(
              (announcement) =>
                  announcement.isActive && announcement.isCurrentlyActive,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return items;
      },
    );
  }

  /*
  Purpose:
  Persist that a show-once announcement was dismissed by the user.

  Response:
  Updates users/{uid}.seenAnnouncements via arrayUnion.

  Business Rules:
  - Only called when announcement.showOnce is true.
  - Does not overwrite the full array; unions a single id.

  Flow:
  1. Validate uid and announcementId are non-empty.
  2. arrayUnion announcementId into seenAnnouncements.

  Side Effects:
  - Writes to Firestore user document.

  Failure Cases:
  - Firestore write errors bubble to caller; modal already dismissed in UI.
  */
  Future<void> markAnnouncementSeen(String uid, String announcementId) async {
    if (uid.isEmpty || announcementId.isEmpty) return;
    await _users.doc(uid).update(<String, dynamic>{
      'seenAnnouncements': FieldValue.arrayUnion(<String>[announcementId]),
    });
  }

  Future<void> dismissLoggingReminder(String uid) async {
    if (uid.isEmpty) return;
    await _users.doc(uid).update(<String, dynamic>{
      'hasDismissedLoggingReminder': true,
    });
  }

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection('announcements');

  /*
  Purpose:
  Stream all announcements for the in-app admin list screen.

  Response:
  Emits all documents ordered newest first, regardless of isActive.

  Business Rules:
  - Admin UI only; not filtered by schedule or active flag.
  - Client sorts by createdAt descending.

  Flow:
  1. Subscribe to full announcements collection.
  2. Map docs to AnnouncementModel.
  3. Sort client-side by createdAt descending.

  Side Effects:
  - Opens a live Firestore listener.

  Failure Cases:
  - Stream errors propagate to Riverpod; admin list shows error state.
  */
  Stream<List<AnnouncementModel>> allAnnouncementsStream() {
    return _resilientAnnouncementStream(
      query: () => _announcements.orderBy('createdAt', descending: true),
      mapDocs: (docs) => docs.map(AnnouncementModel.fromDoc).toList(),
      fallbackMapDocs: (docs) {
        final items = docs.map(AnnouncementModel.fromDoc).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return items;
      },
    );
  }

  Stream<List<AnnouncementModel>> _resilientAnnouncementStream({
    required Query<Map<String, dynamic>> Function() query,
    required List<AnnouncementModel> Function(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    )
    mapDocs,
    required List<AnnouncementModel> Function(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    )
    fallbackMapDocs,
  }) {
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> subscription;
    final controller = StreamController<List<AnnouncementModel>>();
    var usingFallback = false;

    void listenFallback() {
      usingFallback = true;
      subscription = _announcements.snapshots().listen(
        (snap) => controller.add(fallbackMapDocs(snap.docs)),
        onError: controller.addError,
      );
    }

    void listenPrimary() {
      subscription = query().snapshots().listen(
        (snap) => controller.add(mapDocs(snap.docs)),
        onError: (Object error, StackTrace stackTrace) {
          final isIndexError = error is FirebaseException &&
              error.code == 'failed-precondition';
          if (!usingFallback && isIndexError) {
            subscription.cancel();
            listenFallback();
            return;
          }
          controller.addError(error, stackTrace);
        },
      );
    }

    listenPrimary();
    controller.onCancel = () => subscription.cancel();
    return controller.stream;
  }

  /*
  Purpose:
  Create a new announcement document from admin form data.

  Response:
  The new document id.

  Business Rules:
  - createdAt is always server timestamp.
  - adminUid is stored for audit.

  Flow:
  1. Merge caller fields with createdAt and adminUid.
  2. add() to announcements collection.
  3. Return generated doc id.

  Side Effects:
  - Writes one Firestore document.

  Failure Cases:
  - Firestore permission/write errors bubble to caller.
  */
  Future<String> createAnnouncement({
    required Map<String, dynamic> data,
    required String adminUid,
  }) async {
    final doc = await _announcements.add(<String, dynamic>{
      ...data,
      'adminUid': adminUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /*
  Purpose:
  Update an existing announcement from admin form or quick toggle.

  Response:
  None.

  Business Rules:
  - Does not overwrite createdAt or adminUid on update.
  - Partial updates allowed via caller data map.

  Flow:
  1. update() announcements/{id} with provided fields.

  Side Effects:
  - Writes to Firestore.

  Failure Cases:
  - Firestore write errors bubble to caller.
  */
  Future<void> updateAnnouncement(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (id.isEmpty) return;
    await _announcements.doc(id).update(data);
  }

  /*
  Purpose:
  Permanently remove an announcement from Firestore.

  Response:
  None.

  Business Rules:
  - Hard delete; no soft-delete flag.

  Flow:
  1. delete() announcements/{id}.

  Side Effects:
  - Removes document from Firestore.

  Failure Cases:
  - Firestore delete errors bubble to caller.
  */
  Future<void> deleteAnnouncement(String id) async {
    if (id.isEmpty) return;
    await _announcements.doc(id).delete();
  }

  Future<void> updateUserDisplayFields(
    String uid, {
    String? name,
    bool? isAnonymousDisplay,
    bool? showOnLeaderboard,
  }) async {
    final userFields = <String, dynamic>{};
    if (name != null) userFields['name'] = name;
    if (isAnonymousDisplay != null) {
      userFields['isAnonymousDisplay'] = isAnonymousDisplay;
    }
    if (showOnLeaderboard != null) {
      userFields['showOnLeaderboard'] = showOnLeaderboard;
    }
    if (userFields.isNotEmpty) {
      await _users.doc(uid).update(userFields);
    }

    final logFields = <String, dynamic>{};
    if (name != null) logFields['displayName'] = name;
    if (isAnonymousDisplay != null) {
      logFields['isAnonymousDisplay'] = isAnonymousDisplay;
    }
    if (logFields.isEmpty) return;

    final todayDocId =
        '${uid}_${IslamicDateService.getCurrentIslamicDateStringSafe()}';
    final todayRef = _amalLogs.doc(todayDocId);
    final todaySnap = await todayRef.get();
    if (todaySnap.exists) {
      await todayRef.update(logFields);
    }
  }

  /// Updates gender-related preferences on `users/{uid}` (only sends non-null keys).
  Future<void> updateUserGenderPreferences(
    String uid, {
    String? gender,
    bool? specialTimeActive,
    bool? genderPromptDismissed,
  }) async {
    final fields = <String, dynamic>{};
    if (gender != null) fields['gender'] = gender;
    if (specialTimeActive != null) {
      fields['specialTimeActive'] = specialTimeActive;
    }
    if (genderPromptDismissed != null) {
      fields['genderPromptDismissed'] = genderPromptDismissed;
    }
    if (fields.isNotEmpty) {
      await _users.doc(uid).update(fields);
    }
  }

  Stream<UserModel?> userStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDoc(doc);
    });
  }

  Future<Map<String, UserModel>> usersByIds(Iterable<String> ids) async {
    final unique = ids.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (unique.isEmpty) return <String, UserModel>{};
    final out = <String, UserModel>{};
    const chunkSize = 10;
    for (var i = 0; i < unique.length; i += chunkSize) {
      final end = (i + chunkSize > unique.length)
          ? unique.length
          : i + chunkSize;
      final chunk = unique.sublist(i, end);
      final snap = await _users
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        out[doc.id] = UserModel.fromDoc(doc);
      }
    }
    return out;
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
    return getLogsInRange(uid, start, end);
  }

  /*
  Purpose:
  Fetch a user's submitted amal logs for an inclusive Hijri date range.

  Response:
  Sorted list of AmalLogModel by hijriDate ascending.

  Business Rules:
  - Range is inclusive on both ends (Hijri YYYY-MM-DD storage keys).
  - Falls back to uid-only query + client filter when composite index is missing.

  Flow:
  1. Query amal_logs by uid + hijriDate range.
  2. On failed-precondition / FirebaseException, fetch by uid and filter.
  3. Sort ascending by hijriDate.

  Side Effects:
  None beyond Firestore reads.

  Failure Cases:
  FirebaseException from the primary path triggers the fallback; other errors bubble.
  */
  Future<List<AmalLogModel>> getLogsInRange(
    String uid,
    String startHijri,
    String endHijri,
  ) async {
    if (uid.isEmpty || startHijri.isEmpty || endHijri.isEmpty) {
      return const <AmalLogModel>[];
    }
    final start = startHijri.compareTo(endHijri) <= 0 ? startHijri : endHijri;
    final end = startHijri.compareTo(endHijri) <= 0 ? endHijri : startHijri;

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
    String? streakFreezeWeekKey,
    String? lastLogDate,
    String? streakFreezeDate,
  }) async {
    final fields = <String, dynamic>{};
    if (currentStreak != null) fields['currentStreak'] = currentStreak;
    if (bestStreak != null) fields['bestStreak'] = bestStreak;
    if (streakFreezeUsed != null) {
      fields['streakFreezeUsed'] = streakFreezeUsed;
    }
    if (streakFreezeWeekKey != null) {
      fields['streakFreezeWeekKey'] = streakFreezeWeekKey;
    }
    if (lastLogDate != null) fields['lastLogDate'] = lastLogDate;
    if (streakFreezeDate != null) fields['streakFreezeDate'] = streakFreezeDate;
    if (fields.isEmpty) return;
    await _users.doc(uid).update(fields);
  }

  Future<void> saveAmalLog(
    AmalLogModel log,
    List<AmalField> fields,
  ) async {
    final map = log.toFirestoreMap(fields);
    await _amalLogs.doc(log.docId).set(map);
  }

  /// Patches an existing submitted log (amal field values + score + edit metadata).
  /// Uses [DocumentReference.update] — does not overwrite submit metadata or streak fields.
  Future<void> editAmalLog({
    required AmalLogModel updatedLog,
    required List<AmalField> fields,
  }) async {
    await _amalLogs
        .doc(updatedLog.docId)
        .update(updatedLog.toEditFirestoreMap(fields));
  }

  /// Updates [lastLogDate] (Hijri `YYYY-MM-DD`) after a successful submit.
  Future<void> updateUserLastLogDate(String uid, String hijriDate) async {
    await _users.doc(uid).update(<String, dynamic>{'lastLogDate': hijriDate});
  }

  /// Real-time stream of submitted logs for a Hijri day, sorted by score.
  Stream<List<AmalLogModel>> communityDayStream(String hijriDate, {String? genderFilter}) {
    var query = _amalLogs.where('hijriDate', isEqualTo: hijriDate);
    if (genderFilter != null) {
      query = query.where('gender', isEqualTo: genderFilter);
    }
    return query.snapshots().map((snap) {
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
    String? genderFilter,
  }) async {
    try {
      var query = _amalLogs
          .where('hijriDate', isEqualTo: hijriDate);
          
      if (genderFilter != null) {
        query = query.where('gender', isEqualTo: genderFilter);
      }
      
      query = query.orderBy('score', descending: true)
          .limit(_communityPageSize);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final snap = await query.get();
      final rows = snap.docs.map(AmalLogModel.fromDoc).toList();
      final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      return (rows: rows, lastDoc: lastDoc);
    } on FirebaseException {
      // Index fallback: query by date and gender, sort client-side, then paginate locally.
      var query = _amalLogs.where('hijriDate', isEqualTo: hijriDate);
      if (genderFilter != null) {
        query = query.where('gender', isEqualTo: genderFilter);
      }
      final snap = await query.get();
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
  Stream<List<ActivityFeedItemModel>> activityFeedStream({int limit = _activityFeedPageSize, String? genderFilter}) {
    var query = _activityFeed.orderBy('createdAt', descending: true);
    
    if (genderFilter != null) {
      // Note: This requires a composite index on actorGender and createdAt.
      query = _activityFeed
          .where('actorGender', isEqualTo: genderFilter)
          .orderBy('createdAt', descending: true);
    }
    
    return query
        .limit(limit)
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

  Future<List<Map<String, dynamic>>> weeklyLeaderboard() async {
    try {
      return await _weeklyLeaderboardQuery();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> _weeklyLeaderboardQuery() async {
    final end = IslamicDateService.getCurrentIslamicDateStringSafe();
    final start = IslamicDateService.shiftStorageByDays(end, -6);

    final query = await _amalLogs
        .where('hijriDate', isGreaterThanOrEqualTo: start)
        .where('hijriDate', isLessThanOrEqualTo: end)
        .get();

    final grouped = <String, Map<String, dynamic>>{};
    for (final doc in query.docs) {
      final data = doc.data();
      final uid = (data['uid'] as String?) ?? '';
      if (uid.isEmpty) continue;
      final score = (data['score'] as num?)?.toInt() ?? 0;
      final submittedAt = data['submittedAt'];
      final currentTimestamp = submittedAt is Timestamp
          ? submittedAt
          : Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(0));

      final existing = grouped[uid];
      if (existing == null) {
        grouped[uid] = <String, dynamic>{
          'uid': uid,
          'displayName': (data['displayName'] as String?) ?? '',
          'isAnonymousDisplay': (data['isAnonymousDisplay'] as bool?) ?? false,
          'score': score,
          '_latestSubmittedAt': currentTimestamp,
        };
      } else {
        existing['score'] = ((existing['score'] as int?) ?? 0) + score;
        final latest = existing['_latestSubmittedAt'] as Timestamp;
        if (currentTimestamp.compareTo(latest) > 0) {
          existing['displayName'] = (data['displayName'] as String?) ?? '';
          existing['isAnonymousDisplay'] =
              (data['isAnonymousDisplay'] as bool?) ?? false;
          existing['_latestSubmittedAt'] = currentTimestamp;
        }
      }
    }

    final rows = grouped.values.toList()
      ..sort(
        (a, b) =>
            ((b['score'] as int?) ?? 0).compareTo((a['score'] as int?) ?? 0),
      );
    for (final row in rows) {
      row.remove('_latestSubmittedAt');
    }
    return rows;
  }

  Future<List<Map<String, dynamic>>> monthlyLeaderboard() async {
    try {
      return await _monthlyLeaderboardQuery();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> _monthlyLeaderboardQuery() async {
    final end = IslamicDateService.getCurrentIslamicDateStringSafe();
    final parts = end.split('-');
    if (parts.length != 3) return const <Map<String, dynamic>>[];
    final year = parts[0];
    final month = parts[1];
    final start = '$year-$month-01';

    final query = await _amalLogs
        .where('hijriDate', isGreaterThanOrEqualTo: start)
        .where('hijriDate', isLessThanOrEqualTo: end)
        .get();

    final grouped = <String, Map<String, dynamic>>{};
    for (final doc in query.docs) {
      final data = doc.data();
      final uid = (data['uid'] as String?) ?? '';
      if (uid.isEmpty) continue;
      final score = (data['score'] as num?)?.toInt() ?? 0;
      final submittedAt = data['submittedAt'];
      final currentTimestamp = submittedAt is Timestamp
          ? submittedAt
          : Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(0));

      final existing = grouped[uid];
      if (existing == null) {
        grouped[uid] = <String, dynamic>{
          'uid': uid,
          'displayName': (data['displayName'] as String?) ?? '',
          'isAnonymousDisplay': (data['isAnonymousDisplay'] as bool?) ?? false,
          'score': score,
          '_latestSubmittedAt': currentTimestamp,
        };
      } else {
        existing['score'] = ((existing['score'] as int?) ?? 0) + score;
        final latest = existing['_latestSubmittedAt'] as Timestamp;
        if (currentTimestamp.compareTo(latest) > 0) {
          existing['displayName'] = (data['displayName'] as String?) ?? '';
          existing['isAnonymousDisplay'] =
              (data['isAnonymousDisplay'] as bool?) ?? false;
          existing['_latestSubmittedAt'] = currentTimestamp;
        }
      }
    }

    final rows = grouped.values.toList()
      ..sort(
        (a, b) =>
            ((b['score'] as int?) ?? 0).compareTo((a['score'] as int?) ?? 0),
      );
    for (final row in rows) {
      row.remove('_latestSubmittedAt');
    }
    return rows;
  }

  static const int _leaderboardPageSize = 20;

  Future<
    ({List<Map<String, dynamic>> rows, DocumentSnapshot<Map<String, dynamic>>? lastDoc})
  >
  streakLeaderboard({DocumentSnapshot<Map<String, dynamic>>? startAfter, String? genderFilter}) async {
    var query = _users
        .orderBy('currentStreak', descending: true);
        
    if (genderFilter != null) {
       query = _users
           .where('gender', isEqualTo: genderFilter)
           .orderBy('currentStreak', descending: true);
    }
    
    query = query.limit(_leaderboardPageSize);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await query.get();
    } catch (e) {
      print('🔥 [FirestoreService] streakLeaderboard failed (likely missing index). Returning empty list as fallback. Error: $e');
      return (rows: <Map<String, dynamic>>[], lastDoc: null);
    }
    
    final rows = snap.docs.map((doc) {
      final data = doc.data();
      return <String, dynamic>{
        'uid': doc.id,
        'displayName': (data['name'] as String?) ?? '',
        'isAnonymousDisplay': (data['isAnonymousDisplay'] as bool?) ?? false,
        'score': (data['currentStreak'] as num?)?.toInt() ?? 0,
      };
    }).toList();
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
    return (rows: rows, lastDoc: lastDoc);
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
    required String senderName,
    required String recipientUid,
    required String message,
    required String hijriDate,
    String? senderGender,
  }) async {
    final notificationRef = await _notificationItems(recipientUid)
        .add(<String, dynamic>{
          'type': 'dua',
          'message': message,
          if (senderGender != null) 'senderGender': senderGender,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'senderUid': senderUid,
          'senderName': senderName,
          'hijriDate': hijriDate,
        });

    await _activityFeed.add(<String, dynamic>{
      'type': 'dua',
      'message': message,
      'actorUid': senderUid,
      'targetUid': recipientUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    logDuaPushDebug(
      'dua saved to Firestore: notificationId=${notificationRef.id} '
      'senderUid=$senderUid recipientUid=$recipientUid',
    );

    try {
      if (!_duaPushGateway.isConfigured) {
        logDuaPushDebug(
          'push not attempted: gateway not configured recipientUid=$recipientUid',
        );
        return;
      }

      final recipientUser = await _users.doc(recipientUid).get();
      if (!recipientUser.exists) {
        logDuaPushDebug(
          'push not attempted: recipient user doc missing recipientUid=$recipientUid',
        );
        return;
      }

      final recipientToken = (recipientUser.data()?['fcmToken'] as String?)
          ?.trim();
      if (recipientToken == null || recipientToken.isEmpty) {
        logDuaPushDebug(
          'push not attempted: recipient has no fcmToken recipientUid=$recipientUid',
        );
        return;
      }

      logDuaPushDebug(
        'attempting push: recipientUid=$recipientUid tokenLength=${recipientToken.length}',
      );
      final sent = await _duaPushGateway.sendDuaPush(
        recipientFcmToken: recipientToken,
        senderUid: senderUid,
        senderName: senderName,
        recipientUid: recipientUid,
        message: message,
        notificationId: notificationRef.id,
      );
      logDuaPushDebug(
        sent
            ? 'push outcome: sent recipientUid=$recipientUid'
            : 'push outcome: not sent (gateway returned failure) recipientUid=$recipientUid',
      );
    } catch (e, st) {
      logDuaPushDebug(
        'push outcome: not sent (exception) recipientUid=$recipientUid error=$e\n$st',
      );
      // Never block dua write flow if push gateway fails.
    }
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

  Future<void> addActivityFeedItem({
    required String type,
    required String message,
    String? uid,
  }) async {
    await _activityFeed.add(<String, dynamic>{
      'type': type,
      'message': message,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /*
  Purpose:
  Search users by email prefix or name prefix for the admin "target user" picker.

  Response:
  Up to 10 UserModel results ranked by email match first, then name match.

  Business Rules:
  - Minimum query length: 2 characters.
  - Email prefix query uses Firestore >=/<= range trick (case-insensitive via lowercase).
  - Name prefix query is a secondary pass merged client-side.
  - Deduplication by uid across both result sets.
  - Hard cap of 10 results.

  Flow:
  1. Lowercase query.
  2. Run email prefix range query on _users.
  3. Run name prefix range query on _users.
  4. Merge, deduplicate, cap at 10.

  Failure Cases:
  - Returns empty list on Firestore error (non-blocking).
  */
  Future<List<UserModel>> searchUsersByQuery(String query) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const <UserModel>[];

    final end = '$q\uf8ff';
    final results = <String, UserModel>{};

    try {
      // Email prefix search
      final emailSnap = await _users
          .where('email', isGreaterThanOrEqualTo: q)
          .where('email', isLessThanOrEqualTo: end)
          .limit(10)
          .get();
      for (final doc in emailSnap.docs) {
        results[doc.id] = UserModel.fromDoc(doc);
      }
    } catch (_) {}

    try {
      // Name prefix search (Firestore range queries are case-sensitive;
      // names are stored as entered, so we search with original casing too)
      final nameSnap = await _users
          .where('name', isGreaterThanOrEqualTo: query.trim())
          .where('name', isLessThanOrEqualTo: '${query.trim()}\uf8ff')
          .limit(10)
          .get();
      for (final doc in nameSnap.docs) {
        results.putIfAbsent(doc.id, () => UserModel.fromDoc(doc));
      }
    } catch (_) {}

    final list = results.values.toList();
    if (list.length > 10) return list.sublist(0, 10);
    return list;
  }

  // ── Knowledge Battle Validation ──────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _battleInterest =>
      _firestore.collection('battleInterest');

  Future<bool> hasRespondedToBattleTeaser(String uid) async {
    if (uid.isEmpty) return false;
    final doc = await _battleInterest.doc(uid).get();
    return doc.exists;
  }

  Future<void> saveBattleInterest({
    required String uid,
    required String response,
    required String locale,
  }) async {
    if (uid.isEmpty) return;
    await _battleInterest.doc(uid).set(<String, dynamic>{
      'uid': uid,
      'response': response,
      'respondedAt': FieldValue.serverTimestamp(),
      'locale': locale,
    });
  }

  Future<Map<String, int>> getBattleInterestMetrics() async {
    final query = await _battleInterest.get();
    int yes = 0;
    int no = 0;
    int dismissed = 0;
    for (final doc in query.docs) {
      final response = doc.data()['response'] as String?;
      if (response == 'yes') {
        yes++;
      } else if (response == 'no') {
        no++;
      } else if (response == 'dismissed') {
        dismissed++;
      }
    }
    return {
      'yes': yes,
      'no': no,
      'dismissed': dismissed,
    };
  }

  // ── App Config (version update) ──────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _appConfigs =>
      _firestore.collection('app_config');

  Stream<List<AppConfigModel>> appConfigsStream() {
    return _appConfigs.orderBy('createdAt', descending: true).snapshots().map(
      (snap) => snap.docs.map(AppConfigModel.fromDoc).toList(),
    );
  }

  Stream<AppConfigModel?> activeAppConfigStream() {
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> subscription;
    final controller = StreamController<AppConfigModel?>();

    void listenFallback() {
      subscription = _appConfigs.snapshots().listen(
        (snap) {
          final active = snap.docs
              .map(AppConfigModel.fromDoc)
              .where((c) => c.isActive)
              .toList()
            ..sort((a, b) => b.latestVersionCode.compareTo(a.latestVersionCode));
          controller.add(active.isEmpty ? null : active.first);
        },
        onError: controller.addError,
      );
    }

    void listenPrimary() {
      subscription = _appConfigs
          .where('isActive', isEqualTo: true)
          .orderBy('latestVersionCode', descending: true)
          .limit(1)
          .snapshots()
          .listen(
        (snap) {
          if (snap.docs.isEmpty) {
            controller.add(null);
          } else {
            controller.add(AppConfigModel.fromDoc(snap.docs.first));
          }
        },
        onError: (Object error) {
          if (error is FirebaseException && error.code == 'failed-precondition') {
            subscription.cancel();
            listenFallback();
            return;
          }
          controller.addError(error);
        },
      );
    }

    listenPrimary();
    controller.onCancel = () => subscription.cancel();
    return controller.stream;
  }

  Future<String> createAppConfig({
    required Map<String, dynamic> data,
    required String adminUid,
  }) async {
    final doc = await _appConfigs.add(<String, dynamic>{
      ...data,
      'adminUid': adminUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateAppConfig(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (id.isEmpty) return;
    await _appConfigs.doc(id).update(data);
  }

  Future<void> deleteAppConfig(String id) async {
    if (id.isEmpty) return;
    await _appConfigs.doc(id).delete();
  }
}
