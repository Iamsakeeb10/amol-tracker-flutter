import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class BattleResultPlayer {
  final String uid;
  final String name;
  final int score;
  final int totalTimeMs;
  final List<Map<String, dynamic>> answers;

  BattleResultPlayer({
    required this.uid,
    required this.name,
    required this.score,
    required this.totalTimeMs,
    this.answers = const [],
  });

  factory BattleResultPlayer.fromJson(Map<String, dynamic> json) {
    final answersList = json['answers'] as List<dynamic>? ?? [];
    return BattleResultPlayer(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Player',
      score: json['score'] as int? ?? 0,
      totalTimeMs: json['totalTimeMs'] as int? ?? 0,
      answers: answersList.map((e) => e as Map<String, dynamic>).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'score': score,
      'totalTimeMs': totalTimeMs,
      'answers': answers,
    };
  }
}

class BattleResultModel {
  final String id;
  final String topicId;
  final String? winnerUid;
  final List<BattleResultPlayer> players;
  final DateTime? finishedAt;
  final List<Map<String, dynamic>> questions;

  BattleResultModel({
    required this.id,
    required this.topicId,
    this.winnerUid,
    required this.players,
    this.finishedAt,
    this.questions = const [],
  });

  factory BattleResultModel.fromJson(Map<String, dynamic> json) {
    final playersList = json['players'] as List<dynamic>? ?? [];
    final questionsList = json['questions'] as List<dynamic>? ?? [];
    return BattleResultModel(
      id: json['id'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      winnerUid: json['winnerUid'] as String?,
      players: playersList.map((p) => BattleResultPlayer.fromJson(p)).toList(),
      finishedAt: _parseDateTime(json['finishedAt']),
      questions: questionsList.map((e) => e as Map<String, dynamic>).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'winnerUid': winnerUid,
      'players': players.map((p) => p.toJson()).toList(),
      'finishedAt': finishedAt?.toIso8601String(),
      'questions': questions,
    };
  }
}
