import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/lesson_bookmark_model.dart';
import '../../models/lesson_review_schedule_model.dart';

class LmsReviewService {
  LmsReviewService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _reviewsRef(String uid) =>
      _firestore.collection('userProgress').doc(uid).collection('lessonReviews');

  CollectionReference<Map<String, dynamic>> _bookmarksRef(String uid) =>
      _firestore.collection('userProgress').doc(uid).collection('bookmarks');

  /*
  Purpose:
  Schedule spaced repetition review after a lesson is completed.

  Response:
  None.

  Business Rules:
  - First review due 1 day after completion.
  - intervalIndex starts at 0 (1-day interval).

  Flow:
  1. set/merge lessonReviews/{lessonId} with nextReviewAt.

  Side Effects:
  - Writes userProgress/{uid}/lessonReviews/{lessonId}.

  Failure Cases:
  - Firestore errors propagate.
  */
  Future<void> scheduleInitialReview({
    required String uid,
    required String courseId,
    required String lessonId,
    String? lessonTitle,
  }) async {
    if (uid.isEmpty || courseId.isEmpty || lessonId.isEmpty) return;
    final nextReview = DateTime.now().add(const Duration(days: 1));
    await _reviewsRef(uid).doc(lessonId).set(<String, dynamic>{
      'courseId': courseId,
      'nextReviewAt': Timestamp.fromDate(nextReview.toUtc()),
      'intervalIndex': 0,
      if (lessonTitle != null && lessonTitle.isNotEmpty)
        'lessonTitle': lessonTitle,
    }, SetOptions(merge: true));
  }

  Future<void> markReviewComplete({
    required String uid,
    required String lessonId,
  }) async {
    if (uid.isEmpty || lessonId.isEmpty) return;
    final doc = await _reviewsRef(uid).doc(lessonId).get();
    if (!doc.exists) return;
    final schedule = LessonReviewScheduleModel.fromDoc(doc);
    final nextIndex = (schedule.intervalIndex + 1)
        .clamp(0, LessonReviewScheduleModel.reviewIntervalsDays.length - 1);
    final days = LessonReviewScheduleModel.reviewIntervalsDays[nextIndex];
    final nextReview = DateTime.now().add(Duration(days: days));
    await _reviewsRef(uid).doc(lessonId).update(<String, dynamic>{
      'intervalIndex': nextIndex,
      'nextReviewAt': Timestamp.fromDate(nextReview.toUtc()),
      'lastReviewedAt': FieldValue.serverTimestamp(),
    });
  }

  /*
  Purpose:
  Advance spaced-repetition schedule only when a review is actually due.

  Response:
  true when schedule was advanced, false when not yet due or missing.

  Business Rules:
  - No-op if nextReviewAt is still in the future.
  - Delegates to markReviewComplete when due.

  Flow:
  1. Load review doc.
  2. Compare nextReviewAt to now.
  3. Advance interval only if due.

  Side Effects:
  - May update lessonReviews doc and reschedule notifications.

  Failure Cases:
  - Missing doc returns false; Firestore errors propagate.
  */
  Future<bool> markReviewIfDue({
    required String uid,
    required String lessonId,
  }) async {
    if (uid.isEmpty || lessonId.isEmpty) return false;
    final doc = await _reviewsRef(uid).doc(lessonId).get();
    if (!doc.exists) return false;
    final schedule = LessonReviewScheduleModel.fromDoc(doc);
    if (schedule.nextReviewAt.isAfter(DateTime.now())) return false;
    await markReviewComplete(uid: uid, lessonId: lessonId);
    return true;
  }

  Stream<List<LessonReviewScheduleModel>> dueReviewsStream(String uid) {
    if (uid.isEmpty) return Stream.value(const []);
    return _reviewsRef(uid).snapshots().map((snap) {
      final now = DateTime.now();
      return snap.docs
          .map(LessonReviewScheduleModel.fromDoc)
          .where((r) => !r.nextReviewAt.isAfter(now))
          .toList();
    });
  }

  Future<List<LessonReviewScheduleModel>> getUpcomingReviews(
    String uid, {
    int daysAhead = 7,
  }) async {
    if (uid.isEmpty) return const [];
    final snap = await _reviewsRef(uid).get();
    final cutoff = DateTime.now().add(Duration(days: daysAhead));
    return snap.docs
        .map(LessonReviewScheduleModel.fromDoc)
        .where((r) => !r.nextReviewAt.isAfter(cutoff))
        .toList();
  }

  Future<void> toggleBookmark({
    required String uid,
    required String courseId,
    required String lessonId,
    String? lessonTitle,
    String? courseTitle,
  }) async {
    if (uid.isEmpty || courseId.isEmpty || lessonId.isEmpty) return;
    final id = LessonBookmarkModel.bookmarkId(courseId, lessonId);
    final ref = _bookmarksRef(uid).doc(id);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set(<String, dynamic>{
        'courseId': courseId,
        'lessonId': lessonId,
        'createdAt': FieldValue.serverTimestamp(),
        if (lessonTitle != null && lessonTitle.isNotEmpty)
          'lessonTitle': lessonTitle,
        if (courseTitle != null && courseTitle.isNotEmpty)
          'courseTitle': courseTitle,
      });
    }
  }

  Stream<List<LessonBookmarkModel>> bookmarksStream(String uid) {
    if (uid.isEmpty) return Stream.value(const []);
    return _bookmarksRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(LessonBookmarkModel.fromDoc).toList());
  }

  Stream<bool> isBookmarkedStream({
    required String uid,
    required String courseId,
    required String lessonId,
  }) {
    if (uid.isEmpty) return Stream.value(false);
    final id = LessonBookmarkModel.bookmarkId(courseId, lessonId);
    return _bookmarksRef(uid).doc(id).snapshots().map((snap) => snap.exists);
  }
}
