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
  final FeedbackType type;
  final String content;
  final DateTime createdAt;
  final FeedbackStatus status;

  const FeedbackModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'content': content,
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
      type: FeedbackType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => FeedbackType.bug,
      ),
      content: data['content'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      status: FeedbackStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FeedbackStatus.pending,
      ),
    );
  }
}
