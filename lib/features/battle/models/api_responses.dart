import 'battle_model.dart';
import 'question_model.dart';

class CreateBattleResponse {
  final String code;
  final BattleModel battle;

  CreateBattleResponse({required this.code, required this.battle});

  factory CreateBattleResponse.fromJson(Map<String, dynamic> json) {
    return CreateBattleResponse(
      code: json['code'] as String? ?? '',
      battle: BattleModel.fromJson(json['battle'] ?? {}),
    );
  }
}

class JoinBattleResponse {
  final String code;
  final BattleModel battle;

  JoinBattleResponse({required this.code, required this.battle});

  factory JoinBattleResponse.fromJson(Map<String, dynamic> json) {
    return JoinBattleResponse(
      code: json['code'] as String? ?? '',
      battle: BattleModel.fromJson(json['battle'] ?? {}),
    );
  }
}

