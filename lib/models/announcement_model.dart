import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String? arabicText;
  final String? imageUrl;
  final String type;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final bool showOnce;
  final DateTime createdAt;
  final String? actionUrl;
  final String? actionLabel;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.arabicText,
    required this.imageUrl,
    required this.type,
    required this.isActive,
    required this.startsAt,
    required this.expiresAt,
    required this.showOnce,
    required this.createdAt,
    this.actionUrl,
    this.actionLabel,
  });

  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (expiresAt != null && now.isAfter(expiresAt!)) return false;
    return true;
  }

  factory AnnouncementModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return AnnouncementModel(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      arabicText: data['arabicText'] as String?,
      imageUrl: data['imageUrl'] as String?,
      type: (data['type'] as String?) ?? 'announcement',
      isActive: (data['isActive'] as bool?) ?? false,
      startsAt: (data['startsAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      showOnce: (data['showOnce'] as bool?) ?? false,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      actionUrl: data['actionUrl'] as String?,
      actionLabel: data['actionLabel'] as String?,
    );
  }
}
