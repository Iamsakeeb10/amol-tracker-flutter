import 'package:cloud_firestore/cloud_firestore.dart';

class QuizAttemptModel {
  const QuizAttemptModel({
    required this.id,
    required this.quizId,
    required this.courseId,
    required this.score,
    required this.totalQuestions,
    required this.answers,
    required this.timeTakenSeconds,
    required this.completedAt,
    required this.passed,
  });

  final String id;
  final String quizId;
  final String courseId;
  final int score;
  final int totalQuestions;
  final List<int> answers;
  final int timeTakenSeconds;
  final DateTime completedAt;
  final bool passed;

  double get scorePercent =>
      totalQuestions == 0 ? 0 : (score / totalQuestions) * 100;

  factory QuizAttemptModel.fromMap(Map<String, dynamic> map, String id) {
    final completedAt = map['completedAt'];
    return QuizAttemptModel(
      id: id,
      quizId: (map['quizId'] as String?) ?? '',
      courseId: (map['courseId'] as String?) ?? '',
      score: (map['score'] as num?)?.toInt() ?? 0,
      totalQuestions: (map['totalQuestions'] as num?)?.toInt() ?? 0,
      answers: ((map['answers'] as List<dynamic>?) ?? const [])
          .map((item) => (item as num).toInt())
          .toList(),
      timeTakenSeconds: (map['timeTaken'] as num?)?.toInt() ??
          (map['timeTakenSeconds'] as num?)?.toInt() ??
          0,
      completedAt: completedAt is Timestamp
          ? completedAt.toDate()
          : DateTime.now(),
      passed: (map['passed'] as bool?) ?? false,
    );
  }

  factory QuizAttemptModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return QuizAttemptModel.fromMap(
      doc.data() ?? <String, dynamic>{},
      doc.id,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'quizId': quizId,
      'courseId': courseId,
      'score': score,
      'totalQuestions': totalQuestions,
      'answers': answers,
      'timeTaken': timeTakenSeconds,
      'completedAt': Timestamp.fromDate(completedAt.toUtc()),
      'passed': passed,
    };
  }
}
