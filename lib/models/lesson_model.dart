import 'package:cloud_firestore/cloud_firestore.dart';

enum LessonResourceType { youtube, pdf, link, text }

LessonResourceType lessonResourceTypeFromString(String? value) {
  return LessonResourceType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => LessonResourceType.text,
  );
}

class LessonModel {
  const LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.resourceType,
    required this.resourceUrl,
    required this.thumbnailUrl,
    required this.durationMinutes,
    required this.order,
    required this.isPublished,
  });

  final String id;
  final String courseId;
  final String title;
  final String description;
  final LessonResourceType resourceType;
  final String resourceUrl;
  final String thumbnailUrl;
  final int durationMinutes;
  final int order;
  final bool isPublished;

  factory LessonModel.fromMap(
    Map<String, dynamic> map,
    String id, {
    String? courseId,
  }) {
    return LessonModel(
      id: id,
      courseId: courseId ?? (map['courseId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      resourceType: lessonResourceTypeFromString(map['resourceType'] as String?),
      resourceUrl: (map['resourceUrl'] as String?) ?? '',
      thumbnailUrl: (map['thumbnailUrl'] as String?) ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      order: (map['order'] as num?)?.toInt() ?? 0,
      isPublished: (map['isPublished'] as bool?) ?? false,
    );
  }

  factory LessonModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? courseId,
  }) {
    return LessonModel.fromMap(
      doc.data() ?? <String, dynamic>{},
      doc.id,
      courseId: courseId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'courseId': courseId,
      'title': title,
      'description': description,
      'resourceType': resourceType.name,
      'resourceUrl': resourceUrl,
      'thumbnailUrl': thumbnailUrl,
      'durationMinutes': durationMinutes,
      'order': order,
      'isPublished': isPublished,
    };
  }

  LessonModel copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    LessonResourceType? resourceType,
    String? resourceUrl,
    String? thumbnailUrl,
    int? durationMinutes,
    int? order,
    bool? isPublished,
  }) {
    return LessonModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      resourceType: resourceType ?? this.resourceType,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      order: order ?? this.order,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}
