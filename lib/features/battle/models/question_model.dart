class QuestionModel {
  final String id;
  final String topicId;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final String? reference;
  final String difficulty;
  final bool isActive;

  QuestionModel({
    required this.id,
    required this.topicId,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.reference,
    required this.difficulty,
    required this.isActive,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      text: (json['text'] ?? json['textBn'] ?? json['textEn'] ?? '') as String,
      options: List<String>.from(json['options'] ?? json['optionsBn'] ?? json['optionsEn'] ?? []),
      correctIndex: json['correctIndex'] as int? ?? 0,
      explanation: (json['explanation'] ?? json['explanationBn'] ?? json['explanationEn']) as String?,
      reference: (json['reference'] ?? json['referenceBn'] ?? json['referenceEn']) as String?,
      difficulty: json['difficulty'] as String? ?? 'easy',
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'text': text,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'reference': reference,
      'difficulty': difficulty,
      'isActive': isActive,
    };
  }
}
