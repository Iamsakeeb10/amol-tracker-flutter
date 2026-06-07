import 'package:cloud_firestore/cloud_firestore.dart';

enum CourseStatus { draft, published }

CourseStatus courseStatusFromString(String? value) {
  return CourseStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => CourseStatus.draft,
  );
}

class CourseModel {
  const CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.tags,
    required this.status,
    required this.createdBy,
    required this.moderators,
    required this.publishedAt,
    required this.order,
  });

  final String id;
  final String title;
  final String description;
  final String coverImageUrl;
  final List<String> tags;
  final CourseStatus status;
  final String createdBy;
  final List<String> moderators;
  final DateTime? publishedAt;
  final int order;

  bool get isPublished => status == CourseStatus.published;

  factory CourseModel.fromMap(Map<String, dynamic> map, String id) {
    final publishedAt = map['publishedAt'];
    return CourseModel(
      id: id,
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      coverImageUrl: (map['coverImageUrl'] as String?) ?? '',
      tags: ((map['tags'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      status: courseStatusFromString(map['status'] as String?),
      createdBy: (map['createdBy'] as String?) ?? '',
      moderators: ((map['moderators'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      publishedAt: publishedAt is Timestamp ? publishedAt.toDate() : null,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  factory CourseModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return CourseModel.fromMap(doc.data() ?? <String, dynamic>{}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'tags': tags,
      'status': status.name,
      'createdBy': createdBy,
      'moderators': moderators,
      if (publishedAt != null)
        'publishedAt': Timestamp.fromDate(publishedAt!.toUtc()),
      'order': order,
    };
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? coverImageUrl,
    List<String>? tags,
    CourseStatus? status,
    String? createdBy,
    List<String>? moderators,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
    int? order,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      moderators: moderators ?? this.moderators,
      publishedAt: clearPublishedAt ? null : (publishedAt ?? this.publishedAt),
      order: order ?? this.order,
    );
  }
}
