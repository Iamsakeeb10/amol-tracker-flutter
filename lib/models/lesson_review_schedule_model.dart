import 'package:cloud_firestore/cloud_firestore.dart';

class LessonReviewScheduleModel {
  const LessonReviewScheduleModel({
    required this.lessonId,
    required this.courseId,
    required this.nextReviewAt,
    required this.intervalIndex,
    this.lastReviewedAt,
    this.lessonTitle,
  });

  final String lessonId;
  final String courseId;
  final DateTime nextReviewAt;
  final int intervalIndex;
  final DateTime? lastReviewedAt;
  final String? lessonTitle;

  static const reviewIntervalsDays = [1, 3, 7, 21];

  factory LessonReviewScheduleModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final nextReviewAt = data['nextReviewAt'];
    final lastReviewedAt = data['lastReviewedAt'];
    return LessonReviewScheduleModel(
      lessonId: doc.id,
      courseId: (data['courseId'] as String?) ?? '',
      nextReviewAt:
          nextReviewAt is Timestamp ? nextReviewAt.toDate() : DateTime.now(),
      intervalIndex: (data['intervalIndex'] as num?)?.toInt() ?? 0,
      lastReviewedAt:
          lastReviewedAt is Timestamp ? lastReviewedAt.toDate() : null,
      lessonTitle: data['lessonTitle'] as String?,
    );
  }
}
