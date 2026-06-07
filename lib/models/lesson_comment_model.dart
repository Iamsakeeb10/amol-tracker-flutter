import 'package:cloud_firestore/cloud_firestore.dart';

class LessonCommentModel {
  const LessonCommentModel({
    required this.id,
    required this.courseId,
    required this.lessonId,
    required this.authorUid,
    required this.authorName,
    required this.message,
    required this.createdAt,
    this.editedAt,
  });

  final String id;
  final String courseId;
  final String lessonId;
  final String authorUid;
  final String authorName;
  final String message;
  final DateTime createdAt;
  final DateTime? editedAt;

  factory LessonCommentModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String courseId,
    required String lessonId,
  }) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    final editedAt = data['editedAt'];
    return LessonCommentModel(
      id: doc.id,
      courseId: courseId,
      lessonId: lessonId,
      authorUid: (data['authorUid'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      editedAt: editedAt is Timestamp ? editedAt.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'authorUid': authorUid,
      'authorName': authorName,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!.toUtc()),
    };
  }
}
