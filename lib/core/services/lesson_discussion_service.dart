import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/lesson_comment_model.dart';

class LessonDiscussionService {
  LessonDiscussionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _commentsRef(
    String courseId,
    String lessonId,
  ) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .doc(lessonId)
        .collection('comments');
  }

  Stream<List<LessonCommentModel>> commentsStream({
    required String courseId,
    required String lessonId,
  }) {
    return _commentsRef(courseId, lessonId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map(
            (doc) => LessonCommentModel.fromDoc(
              doc,
              courseId: courseId,
              lessonId: lessonId,
            ),
          )
          .toList();
    });
  }

  /*
  Purpose:
  Post a new comment on a lesson discussion thread.

  Response:
  New comment document ID.

  Business Rules:
  - message must be non-empty after trim.
  - authorUid and authorName stored for display.

  Flow:
  1. Validate inputs.
  2. add() with server timestamp for createdAt.

  Side Effects:
  - Writes to courses/.../lessons/.../comments.

  Failure Cases:
  - Empty message throws ArgumentError; Firestore errors propagate.
  */
  Future<String> postComment({
    required String courseId,
    required String lessonId,
    required String authorUid,
    required String authorName,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (courseId.isEmpty ||
        lessonId.isEmpty ||
        authorUid.isEmpty ||
        trimmed.isEmpty) {
      throw ArgumentError('Invalid comment payload.');
    }

    final doc = await _commentsRef(courseId, lessonId).add(<String, dynamic>{
      'authorUid': authorUid,
      'authorName': authorName.trim().isEmpty ? 'Student' : authorName.trim(),
      'message': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /*
  Purpose:
  Edit an existing comment authored by the current user.

  Response:
  None.

  Business Rules:
  - Only non-empty trimmed messages up to 500 chars.
  - authorUid must match caller (enforced in UI; rules enforce server-side).

  Flow:
  1. Validate inputs.
  2. update() message and editedAt server timestamp.

  Side Effects:
  - Updates courses/.../lessons/.../comments/{commentId}.

  Failure Cases:
  - Empty message throws ArgumentError; Firestore errors propagate.
  */
  Future<void> editComment({
    required String courseId,
    required String lessonId,
    required String commentId,
    required String authorUid,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (courseId.isEmpty ||
        lessonId.isEmpty ||
        commentId.isEmpty ||
        authorUid.isEmpty ||
        trimmed.isEmpty ||
        trimmed.length > 500) {
      throw ArgumentError('Invalid comment edit payload.');
    }

    await _commentsRef(courseId, lessonId).doc(commentId).update(<String, dynamic>{
      'message': trimmed,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment({
    required String courseId,
    required String lessonId,
    required String commentId,
  }) async {
    if (commentId.isEmpty) return;
    await _commentsRef(courseId, lessonId).doc(commentId).delete();
  }
}
