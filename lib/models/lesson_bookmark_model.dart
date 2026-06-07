import 'package:cloud_firestore/cloud_firestore.dart';

class LessonBookmarkModel {
  const LessonBookmarkModel({
    required this.id,
    required this.courseId,
    required this.lessonId,
    required this.createdAt,
    this.lessonTitle,
    this.courseTitle,
  });

  final String id;
  final String courseId;
  final String lessonId;
  final DateTime createdAt;
  final String? lessonTitle;
  final String? courseTitle;

  static String bookmarkId(String courseId, String lessonId) =>
      '${courseId}_$lessonId';

  factory LessonBookmarkModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return LessonBookmarkModel(
      id: doc.id,
      courseId: (data['courseId'] as String?) ?? '',
      lessonId: (data['lessonId'] as String?) ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      lessonTitle: data['lessonTitle'] as String?,
      courseTitle: data['courseTitle'] as String?,
    );
  }
}
