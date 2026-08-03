import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType {
  bug,
  feature,
}

enum FeedbackStatus {
  pending,
  reviewed,
  resolved,
}

class FeedbackModel {
  final String id;
  final String userId;
  final String? userEmail;
  final FeedbackType type;
  final String content;
  final String? appVersion;
  final String? platform;
  final DateTime createdAt;
  final FeedbackStatus status;

  const FeedbackModel({
    required this.id,
    required this.userId,
    this.userEmail,
    required this.type,
    required this.content,
    this.appVersion,
    this.platform,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      if (userEmail != null) 'userEmail': userEmail,
      'type': type.name,
      'content': content,
      if (appVersion != null) 'appVersion': appVersion,
      if (platform != null) 'platform': platform,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
    };
  }

  factory FeedbackModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    
    return FeedbackModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userEmail: data['userEmail'] as String?,
      type: FeedbackType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => FeedbackType.bug,
      ),
      content: data['content'] as String? ?? '',
      appVersion: data['appVersion'] as String?,
      platform: data['platform'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      status: FeedbackStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FeedbackStatus.pending,
      ),
    );
  }
}
