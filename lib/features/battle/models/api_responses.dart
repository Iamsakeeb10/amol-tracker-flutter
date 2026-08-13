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

class SubmitAnswerResponse {
  final int score;
  final bool isCorrect;
  final int correctIndex;
  final String? explanationEn;
  final String? explanationBn;

  SubmitAnswerResponse({
    required this.score,
    required this.isCorrect,
    required this.correctIndex,
    this.explanationEn,
    this.explanationBn,
  });

  factory SubmitAnswerResponse.fromJson(Map<String, dynamic> json) {
    return SubmitAnswerResponse(
      score: json['score'] as int? ?? 0,
      isCorrect: json['isCorrect'] as bool? ?? false,
      correctIndex: json['correctIndex'] as int? ?? 0,
      explanationEn: json['explanationEn'] as String?,
      explanationBn: json['explanationBn'] as String?,
    );
  }
}

class NextQuestionResponse {
  final int? nextQuestionIndex;
  final bool isFinished;
  final QuestionModel? question;

  NextQuestionResponse({
    this.nextQuestionIndex,
    required this.isFinished,
    this.question,
  });

  factory NextQuestionResponse.fromJson(Map<String, dynamic> json) {
    return NextQuestionResponse(
      nextQuestionIndex: json['nextQuestionIndex'] as int?,
      isFinished: json['isFinished'] as bool? ?? false,
      question: json['question'] != null ? QuestionModel.fromJson(json['question']) : null,
    );
  }
}
