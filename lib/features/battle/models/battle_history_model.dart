import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class BattleHistoryOpponent {
  final String uid;
  final String name;

  BattleHistoryOpponent({
    required this.uid,
    required this.name,
  });

  factory BattleHistoryOpponent.fromJson(Map<String, dynamic> json) {
    return BattleHistoryOpponent(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Player',
    );
  }
}

class BattleHistoryModel {
  final String battleId;
  final List<BattleHistoryOpponent> opponents;
  final String topicId;
  final String result; // 'win', 'loss', 'draw'
  final int score;
  final DateTime? date;

  BattleHistoryModel({
    required this.battleId,
    required this.opponents,
    required this.topicId,
    required this.result,
    required this.score,
    this.date,
  });

  factory BattleHistoryModel.fromJson(Map<String, dynamic> json) {
    final ops = json['opponents'] as List<dynamic>? ?? [];
    
    // Fallback if 'opponentUids' was used previously.
    List<BattleHistoryOpponent> parsedOpponents = [];
    if (ops.isNotEmpty && ops.first is Map) {
      parsedOpponents = ops.map((e) => BattleHistoryOpponent.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      final oldUids = json['opponentUids'] as List<dynamic>? ?? [];
      parsedOpponents = oldUids.map((uid) => BattleHistoryOpponent(uid: uid.toString(), name: 'Unknown Player')).toList();
    }

    return BattleHistoryModel(
      battleId: json['battleId'] as String? ?? '',
      opponents: parsedOpponents,
      topicId: json['topicId'] as String? ?? '',
      result: json['result'] as String? ?? 'loss',
      score: json['score'] as int? ?? 0,
      date: _parseDateTime(json['date']),
    );
  }
}
