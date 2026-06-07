import 'package:cloud_firestore/cloud_firestore.dart';

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: (map['id'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      options: ((map['options'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: (map['explanation'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }

  QuizQuestion copyWith({
    String? id,
    String? text,
    List<String>? options,
    int? correctIndex,
    String? explanation,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      text: text ?? this.text,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      explanation: explanation ?? this.explanation,
    );
  }
}

List<QuizQuestion> quizQuestionsFromList(List<dynamic>? raw) {
  return (raw ?? const [])
      .whereType<Map>()
      .map((item) => QuizQuestion.fromMap(Map<String, dynamic>.from(item)))
      .toList();
}

class QuizModel {
  const QuizModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.lessonId,
    required this.timeLimitSeconds,
    required this.passingScore,
    required this.questions,
  });

  final String id;
  final String courseId;
  final String title;
  final String? lessonId;
  final int timeLimitSeconds;
  final int passingScore;
  final List<QuizQuestion> questions;

  bool get isCourseLevel => lessonId == null || lessonId!.isEmpty;

  int get questionCount => questions.length;

  factory QuizModel.fromMap(
    Map<String, dynamic> map,
    String id, {
    String? courseId,
  }) {
    return QuizModel(
      id: id,
      courseId: courseId ?? (map['courseId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      lessonId: map['lessonId'] as String?,
      timeLimitSeconds: (map['timeLimitSeconds'] as num?)?.toInt() ?? 0,
      passingScore: (map['passingScore'] as num?)?.toInt() ?? 0,
      questions: quizQuestionsFromList(map['questions'] as List<dynamic>?),
    );
  }

  factory QuizModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? courseId,
  }) {
    return QuizModel.fromMap(
      doc.data() ?? <String, dynamic>{},
      doc.id,
      courseId: courseId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'courseId': courseId,
      'title': title,
      if (lessonId != null && lessonId!.isNotEmpty) 'lessonId': lessonId,
      'timeLimitSeconds': timeLimitSeconds,
      'passingScore': passingScore,
      'questions': questions.map((question) => question.toMap()).toList(),
    };
  }

  QuizModel copyWith({
    String? id,
    String? courseId,
    String? title,
    String? lessonId,
    bool clearLessonId = false,
    int? timeLimitSeconds,
    int? passingScore,
    List<QuizQuestion>? questions,
  }) {
    return QuizModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      lessonId: clearLessonId ? null : (lessonId ?? this.lessonId),
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      passingScore: passingScore ?? this.passingScore,
      questions: questions ?? this.questions,
    );
  }
}
