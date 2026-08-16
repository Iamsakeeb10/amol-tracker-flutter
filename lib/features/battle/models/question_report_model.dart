import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionReportModel {
  final String id;
  final String questionId;
  final String questionText;
  final String reportedByUserId;
  final String reportedByUserName;
  final String reason;
  final String? details;
  final DateTime createdAt;
  final String status; // 'pending', 'resolved', 'dismissed'

  QuestionReportModel({
    required this.id,
    required this.questionId,
    required this.questionText,
    required this.reportedByUserId,
    required this.reportedByUserName,
    required this.reason,
    this.details,
    required this.createdAt,
    this.status = 'pending',
  });

  factory QuestionReportModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return QuestionReportModel(
      id: doc.id,
      questionId: data['questionId'] as String? ?? '',
      questionText: data['questionText'] as String? ?? '',
      reportedByUserId: data['reportedByUserId'] as String? ?? '',
      reportedByUserName: data['reportedByUserName'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      details: data['details'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'reportedByUserId': reportedByUserId,
      'reportedByUserName': reportedByUserName,
      'reason': reason,
      'details': details,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  QuestionReportModel copyWith({
    String? status,
  }) {
    return QuestionReportModel(
      id: id,
      questionId: questionId,
      questionText: questionText,
      reportedByUserId: reportedByUserId,
      reportedByUserName: reportedByUserName,
      reason: reason,
      details: details,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}
