import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityFeedItemModel {
  ActivityFeedItemModel({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.actorUid,
    this.targetUid,
  });

  final String id;
  final String type;
  final String message;
  final DateTime createdAt;
  final String? actorUid;
  final String? targetUid;

  factory ActivityFeedItemModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final ts = data['createdAt'];
    return ActivityFeedItemModel(
      id: doc.id,
      type: (data['type'] as String?) ?? 'system',
      message: (data['message'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      actorUid: (data['actorUid'] as String?) ?? (data['uid'] as String?),
      targetUid: data['targetUid'] as String?,
    );
  }
}
