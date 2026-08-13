import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class BattleHistoryModel {
  final String battleId;
  final String topicId;
  final String result; // 'win', 'loss', 'draw'
  final int score;
  final DateTime? date;

  BattleHistoryModel({
    required this.battleId,
    required this.topicId,
    required this.result,
    required this.score,
    this.date,
  });

  factory BattleHistoryModel.fromJson(Map<String, dynamic> json) {
    return BattleHistoryModel(
      battleId: json['battleId'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      result: json['result'] as String? ?? 'loss',
      score: json['score'] as int? ?? 0,
      date: _parseDateTime(json['date']),
    );
  }
}
