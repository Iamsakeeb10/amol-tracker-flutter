import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.senderUid,
    this.senderName,
  });

  final String id;
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? senderUid;
  final String? senderName;

  factory NotificationModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return NotificationModel(
      id: doc.id,
      type: (data['type'] as String?) ?? 'community',
      message: (data['message'] as String?) ?? '',
      isRead: (data['isRead'] as bool?) ?? false,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      senderUid: data['senderUid'] as String?,
      senderName: data['senderName'] as String?,
    );
  }
}
