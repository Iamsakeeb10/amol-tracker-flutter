class QuestionModel {
  final String id;
  final String topicId;
  final String textEn;
  final String textBn;
  final List<String> optionsEn;
  final List<String> optionsBn;
  final int correctIndex;
  final String? explanationEn;
  final String? explanationBn;
  final String? referenceEn;
  final String? referenceBn;
  final String difficulty;
  final bool isActive;

  QuestionModel({
    required this.id,
    required this.topicId,
    required this.textEn,
    required this.textBn,
    required this.optionsEn,
    required this.optionsBn,
    required this.correctIndex,
    this.explanationEn,
    this.explanationBn,
    this.referenceEn,
    this.referenceBn,
    required this.difficulty,
    required this.isActive,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      textEn: json['textEn'] as String? ?? '',
      textBn: json['textBn'] as String? ?? '',
      optionsEn: List<String>.from(json['optionsEn'] ?? []),
      optionsBn: List<String>.from(json['optionsBn'] ?? []),
      correctIndex: json['correctIndex'] as int? ?? 0,
      explanationEn: json['explanationEn'] as String?,
      explanationBn: json['explanationBn'] as String?,
      referenceEn: json['referenceEn'] as String?,
      referenceBn: json['referenceBn'] as String?,
      difficulty: json['difficulty'] as String? ?? 'easy',
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'textEn': textEn,
      'textBn': textBn,
      'optionsEn': optionsEn,
      'optionsBn': optionsBn,
      'correctIndex': correctIndex,
      'explanationEn': explanationEn,
      'explanationBn': explanationBn,
      'referenceEn': referenceEn,
      'referenceBn': referenceBn,
      'difficulty': difficulty,
      'isActive': isActive,
    };
  }
}
