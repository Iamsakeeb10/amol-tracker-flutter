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
  final Map<String, dynamic>? players;
  final List<String>? readyUids;
  final List<String>? forfeitedUids;
  final int questionCount;
  final int timeLimitSeconds;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final List<String>? questionIds;
  final String? winnerUid;

  BattleModel({
    required this.id,
    required this.topicId,
    required this.status,
    required this.hostUid,
    required this.playerUids,
    this.players,
    this.readyUids,
    this.forfeitedUids,
    required this.questionCount,
    required this.timeLimitSeconds,
    this.createdAt,
    this.startedAt,
    this.questionIds,
    this.winnerUid,
  });

  factory BattleModel.fromJson(Map<String, dynamic> json) {
    final players = json['players'] as Map<String, dynamic>? ?? {};

    return BattleModel(
      id: json['id'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      status: json['status'] as String? ?? 'waiting',
      hostUid: json['hostUid'] as String? ?? '',
      playerUids: List<String>.from(json['playerUids'] ?? []),
      players: players,
      readyUids: json['readyUids'] != null ? List<String>.from(json['readyUids']) : null,
      forfeitedUids: json['forfeitedUids'] != null ? List<String>.from(json['forfeitedUids']) : null,
      questionCount: json['questionCount'] as int? ?? 0,
      timeLimitSeconds: json['timeLimitSeconds'] as int? ?? 300,
      createdAt: _parseDateTime(json['createdAt']),
      startedAt: _parseDateTime(json['startedAt']),
      questionIds: json['questionIds'] != null ? List<String>.from(json['questionIds']) : null,
      winnerUid: json['winnerUid'] as String?,
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
      'timeLimitSeconds': timeLimitSeconds,
      'createdAt': createdAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'questionIds': questionIds,
      'winnerUid': winnerUid,
    };
  }
}
