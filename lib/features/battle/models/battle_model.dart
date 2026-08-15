import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles both Firestore [Timestamp] objects and ISO-8601 [String]s.
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class BattleModel {
  final String id;
  final String topicId;
  final String status; // 'waiting', 'active', 'finished', 'cancelled', 'expired'
  final String hostUid;
  final List<String> playerUids;
  final List<String>? readyUids;
  final List<String>? forfeitedUids;
  final int questionCount;
  final int secondsPerQuestion;
  final DateTime? createdAt;
  final DateTime? questionRevealedAt;
  final int currentQuestionIndex;
  final List<String>? questionIds;
  final String? winnerUid;
  final Map<String, dynamic>? currentQuestion;
  final Map<String, dynamic>? revealedAnswers;

  BattleModel({
    required this.id,
    required this.topicId,
    required this.status,
    required this.hostUid,
    required this.playerUids,
    this.readyUids,
    this.forfeitedUids,
    required this.questionCount,
    required this.secondsPerQuestion,
    this.createdAt,
    this.questionRevealedAt,
    required this.currentQuestionIndex,
    this.questionIds,
    this.winnerUid,
    this.currentQuestion,
    this.revealedAnswers,
  });

  factory BattleModel.fromJson(Map<String, dynamic> json) {
    return BattleModel(
      id: json['id'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      status: json['status'] as String? ?? 'waiting',
      hostUid: json['hostUid'] as String? ?? '',
      playerUids: List<String>.from(json['playerUids'] ?? []),
      readyUids: json['readyUids'] != null ? List<String>.from(json['readyUids']) : null,
      forfeitedUids: json['forfeitedUids'] != null ? List<String>.from(json['forfeitedUids']) : null,
      questionCount: json['questionCount'] as int? ?? 0,
      secondsPerQuestion: json['secondsPerQuestion'] as int? ?? 15,
      createdAt: _parseDateTime(json['createdAt']),
      questionRevealedAt: _parseDateTime(json['questionRevealedAt']),
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      questionIds: json['questionIds'] != null ? List<String>.from(json['questionIds']) : null,
      winnerUid: json['winnerUid'] as String?,
      currentQuestion: json['currentQuestion'] as Map<String, dynamic>?,
      revealedAnswers: json['revealedAnswers'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'status': status,
      'hostUid': hostUid,
      'playerUids': playerUids,
      'readyUids': readyUids,
      'forfeitedUids': forfeitedUids,
      'questionCount': questionCount,
      'secondsPerQuestion': secondsPerQuestion,
      'createdAt': createdAt?.toIso8601String(),
      'questionRevealedAt': questionRevealedAt?.toIso8601String(),
      'currentQuestionIndex': currentQuestionIndex,
      'questionIds': questionIds,
      'winnerUid': winnerUid,
      'currentQuestion': currentQuestion,
      'revealedAnswers': revealedAnswers,
    };
  }
}
