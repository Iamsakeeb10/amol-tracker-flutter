import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/lesson_review_schedule_model.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';

/// Writes inbox nudges when lesson reviews are severely overdue (2+ days).
class LmsReviewNudgeService {
  LmsReviewNudgeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _nudgePrefPrefix = 'lms_review_nudge_';
  static const Duration _nudgeCooldown = Duration(hours: 24);
  static const Duration _overdueThreshold = Duration(days: 2);

  CollectionReference<Map<String, dynamic>> _reviewsRef(String uid) =>
      _firestore.collection('userProgress').doc(uid).collection('lessonReviews');

  CollectionReference<Map<String, dynamic>> _notificationItems(String uid) =>
      _firestore.collection('notifications').doc(uid).collection('items');

  /*
  Purpose:
  Nudge enrolled learners when spaced-repetition reviews are 2+ days overdue.

  Response:
  Count of inbox nudges written this run.

  Business Rules:
  - Respects study-review notification preference.
  - At most one nudge per lesson per 24h (local cooldown).
  - Writes notifications/{uid}/items with type syllabus_review.

  Flow:
  1. Load overdue lessonReviews for signed-in user.
  2. Filter reviews overdue by >= 2 days.
  3. Skip lessons nudged within cooldown window.
  4. Write inbox item with courseId/lessonId metadata.

  Side Effects:
  - Firestore notification inbox writes.

  Failure Cases:
  - Unsigned user returns 0; Firestore errors are swallowed per lesson.
  */
  Future<int> nudgeIfSeverelyOverdue() async {
    if (!NotificationService.instance.isStudyReviewEnabled) return 0;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final snap = await _reviewsRef(user.uid).get();
    final now = DateTime.now();
    final cutoff = now.subtract(_overdueThreshold);
    var nudged = 0;

    for (final doc in snap.docs) {
      final schedule = LessonReviewScheduleModel.fromDoc(doc);
      if (schedule.nextReviewAt.isAfter(cutoff)) continue;
      if (!_shouldNudge(schedule.lessonId)) continue;

      final title = (schedule.lessonTitle ?? '').trim();
      final message = _nudgeMessage(title);
      try {
        await _notificationItems(user.uid).add(<String, dynamic>{
          'type': 'syllabus_review',
          'message': message,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'courseId': schedule.courseId,
          'lessonId': schedule.lessonId,
        });
        await _markNudged(schedule.lessonId);
        nudged += 1;
      } catch (_) {
        // Continue with other overdue lessons.
      }
    }

    return nudged;
  }

  bool _shouldNudge(String lessonId) {
    final raw = LocalStorageService.getPref<String>(
      '$_nudgePrefPrefix$lessonId',
      '',
    );
    if (raw.isEmpty) return true;
    final last = DateTime.tryParse(raw);
    if (last == null) return true;
    return DateTime.now().difference(last) >= _nudgeCooldown;
  }

  Future<void> _markNudged(String lessonId) async {
    await LocalStorageService.setPref(
      '$_nudgePrefPrefix$lessonId',
      DateTime.now().toIso8601String(),
    );
  }

  String _nudgeMessage(String lessonTitle) {
    final locale = LocalStorageService.getPref<String>('app_locale', 'bn');
    final label = lessonTitle.isEmpty
        ? (locale.startsWith('bn') ? 'আপনার পাঠ' : 'your lesson')
        : lessonTitle;
    if (locale.startsWith('bn')) {
      return 'পুনরায় দেখুন: $label (২+ দিন বিলম্বিত)';
    }
    return 'Time to review: $label (2+ days overdue)';
  }
}
