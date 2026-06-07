import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgressModel {
  const UserProgressModel({
    required this.courseId,
    required this.enrolledAt,
    required this.completedLessons,
    required this.completedAt,
  });

  final String courseId;
  final DateTime enrolledAt;
  final List<String> completedLessons;
  final DateTime? completedAt;

  bool get isCourseCompleted => completedAt != null;

  bool isLessonCompleted(String lessonId) =>
      completedLessons.contains(lessonId);

  double completionPercent(int totalLessons) {
    if (totalLessons <= 0) return 0;
    return (completedLessons.length / totalLessons).clamp(0.0, 1.0);
  }

  factory UserProgressModel.fromMap(
    Map<String, dynamic> map,
    String courseId,
  ) {
    final enrolledAt = map['enrolledAt'];
    final completedAt = map['completedAt'];
    return UserProgressModel(
      courseId: courseId,
      enrolledAt: enrolledAt is Timestamp
          ? enrolledAt.toDate()
          : DateTime.now(),
      completedLessons:
          ((map['completedLessons'] as List<dynamic>?) ?? const [])
              .map((item) => item.toString())
              .toList(),
      completedAt: completedAt is Timestamp ? completedAt.toDate() : null,
    );
  }

  factory UserProgressModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return UserProgressModel.fromMap(
      doc.data() ?? <String, dynamic>{},
      doc.id,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enrolledAt': Timestamp.fromDate(enrolledAt.toUtc()),
      'completedLessons': completedLessons,
      if (completedAt != null)
        'completedAt': Timestamp.fromDate(completedAt!.toUtc()),
    };
  }

  UserProgressModel copyWith({
    String? courseId,
    DateTime? enrolledAt,
    List<String>? completedLessons,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return UserProgressModel(
      courseId: courseId ?? this.courseId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      completedLessons: completedLessons ?? this.completedLessons,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }
}
