class PlayerAnswerModel {
  final String uid;
  final String questionId;
  final int? selectedIndex;
  final int responseTimeMs;
  final int score;
  final bool isCorrect;

  PlayerAnswerModel({
    required this.uid,
    required this.questionId,
    this.selectedIndex,
    required this.responseTimeMs,
    required this.score,
    required this.isCorrect,
  });

  factory PlayerAnswerModel.fromJson(Map<String, dynamic> json) {
    return PlayerAnswerModel(
      uid: json['uid'] as String? ?? '',
      questionId: json['questionId'] as String? ?? '',
      selectedIndex: json['selectedIndex'] as int?,
      responseTimeMs: json['responseTimeMs'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'questionId': questionId,
      'selectedIndex': selectedIndex,
      'responseTimeMs': responseTimeMs,
      'score': score,
      'isCorrect': isCorrect,
    };
  }
}
