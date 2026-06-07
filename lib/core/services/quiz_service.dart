import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/quiz_attempt_model.dart';
import '../../models/quiz_model.dart';

typedef QuizScoreResult = ({int score, int totalQuestions, bool passed});

class QuizService {
  QuizService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection('courses');

  CollectionReference<Map<String, dynamic>> _quizzes(String courseId) =>
      _courses.doc(courseId).collection('quizzes');

  CollectionReference<Map<String, dynamic>> _userQuizAttempts(String uid) =>
      _firestore.collection('userProgress').doc(uid).collection('quizAttempts');

  Future<String> createQuiz(QuizModel quiz) async {
    if (quiz.courseId.isEmpty) {
      throw ArgumentError('quiz.courseId must not be empty');
    }
    final doc = await _quizzes(quiz.courseId).add(quiz.toMap());
    return doc.id;
  }

  Future<void> updateQuiz(QuizModel quiz) async {
    if (quiz.courseId.isEmpty || quiz.id.isEmpty) return;
    await _quizzes(quiz.courseId).doc(quiz.id).update(quiz.toMap());
  }

  Future<void> deleteQuiz(String courseId, String quizId) async {
    if (courseId.isEmpty || quizId.isEmpty) return;
    await _quizzes(courseId).doc(quizId).delete();
  }

  Future<QuizModel?> getQuiz(String courseId, String quizId) async {
    if (courseId.isEmpty || quizId.isEmpty) return null;
    final snap = await _quizzes(courseId).doc(quizId).get();
    if (!snap.exists) return null;
    return QuizModel.fromDoc(snap, courseId: courseId);
  }

  Stream<QuizModel?> quizStream(String courseId, String quizId) {
    if (courseId.isEmpty || quizId.isEmpty) {
      return Stream<QuizModel?>.value(null);
    }
    return _quizzes(courseId).doc(quizId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return QuizModel.fromDoc(doc, courseId: courseId);
    });
  }

  Stream<List<QuizModel>> quizzesForCourseStream(String courseId) {
    if (courseId.isEmpty) {
      return Stream<List<QuizModel>>.value(const []);
    }
    return _quizzes(courseId).snapshots().map(
          (snap) => snap.docs
              .map((doc) => QuizModel.fromDoc(doc, courseId: courseId))
              .toList(),
        );
  }

  Stream<List<QuizModel>> quizzesForLessonStream(
    String courseId,
    String lessonId,
  ) {
    if (courseId.isEmpty || lessonId.isEmpty) {
      return Stream<List<QuizModel>>.value(const []);
    }
    return quizzesForCourseStream(courseId).map(
      (quizzes) => quizzes
          .where((quiz) => quiz.lessonId == lessonId)
          .toList(growable: false),
    );
  }

  Stream<List<QuizModel>> courseLevelQuizzesStream(String courseId) {
    if (courseId.isEmpty) {
      return Stream<List<QuizModel>>.value(const []);
    }
    return quizzesForCourseStream(courseId).map(
      (quizzes) =>
          quizzes.where((quiz) => quiz.isCourseLevel).toList(growable: false),
    );
  }

  /*
  Purpose:
  Score a quiz attempt by comparing selected answers to correct indices.

  Response:
  Record with score, totalQuestions, and passed flag.

  Business Rules:
  - One point per correctly answered question.
  - passed when score >= quiz.passingScore (absolute count, not percent).
  - Out-of-range answer indices count as incorrect.

  Flow:
  1. Iterate questions in order.
  2. Compare answers[i] to question.correctIndex when in range.
  3. Derive passed from passingScore threshold.

  Side Effects:
  - None (pure calculation).

  Failure Cases:
  - Empty questions list yields score 0 and passed false unless passingScore is 0.
  */
  QuizScoreResult calculateScore({
    required QuizModel quiz,
    required List<int> answers,
  }) {
    final total = quiz.questions.length;
    var score = 0;

    for (var i = 0; i < quiz.questions.length; i++) {
      if (i >= answers.length) continue;
      if (answers[i] == quiz.questions[i].correctIndex) {
        score++;
      }
    }

    final passed = total == 0
        ? quiz.passingScore <= 0
        : score >= quiz.passingScore;

    return (score: score, totalQuestions: total, passed: passed);
  }

  /*
  Purpose:
  Persist a completed quiz attempt after scoring.

  Response:
  The new attempt document id.

  Business Rules:
  - Score is computed server-side in app layer before write.
  - completedAt uses server timestamp at write time.
  - answers length may be shorter than question count (unanswered = wrong).

  Flow:
  1. calculateScore() from quiz + answers.
  2. Build QuizAttemptModel.
  3. add() under userProgress/{uid}/quizAttempts/.

  Side Effects:
  - Writes one Firestore document.

  Failure Cases:
  - Firestore write errors bubble to caller.
  */
  Future<String> submitQuizAttempt({
    required String uid,
    required QuizModel quiz,
    required List<int> answers,
    required int timeTakenSeconds,
  }) async {
    if (uid.isEmpty) {
      throw ArgumentError('uid must not be empty');
    }
    if (quiz.courseId.isEmpty || quiz.id.isEmpty) {
      throw ArgumentError('quiz must have courseId and id');
    }

    final result = calculateScore(quiz: quiz, answers: answers);
    final attempt = QuizAttemptModel(
      id: '',
      quizId: quiz.id,
      courseId: quiz.courseId,
      score: result.score,
      totalQuestions: result.totalQuestions,
      answers: answers,
      timeTakenSeconds: timeTakenSeconds,
      completedAt: DateTime.now().toUtc(),
      passed: result.passed,
    );

    final data = attempt.toMap()
      ..['completedAt'] = FieldValue.serverTimestamp();

    final doc = await _userQuizAttempts(uid).add(data);
    return doc.id;
  }

  Future<void> saveQuizAttempt(String uid, QuizAttemptModel attempt) async {
    if (uid.isEmpty) return;
    final data = attempt.toMap();
    if (attempt.id.isEmpty) {
      data['completedAt'] = FieldValue.serverTimestamp();
      await _userQuizAttempts(uid).add(data);
      return;
    }
    await _userQuizAttempts(uid).doc(attempt.id).set(data);
  }

  Future<QuizAttemptModel?> getQuizAttempt(
    String uid,
    String attemptId,
  ) async {
    if (uid.isEmpty || attemptId.isEmpty) return null;
    final snap = await _userQuizAttempts(uid).doc(attemptId).get();
    if (!snap.exists) return null;
    return QuizAttemptModel.fromDoc(snap);
  }

  Stream<List<QuizAttemptModel>> quizAttemptsStream(
    String uid, {
    String? quizId,
    String? courseId,
  }) {
    if (uid.isEmpty) {
      return Stream<List<QuizAttemptModel>>.value(const []);
    }

    Query<Map<String, dynamic>> query = _userQuizAttempts(uid);
    if (quizId != null && quizId.isNotEmpty) {
      query = query.where('quizId', isEqualTo: quizId);
    } else if (courseId != null && courseId.isNotEmpty) {
      query = query.where('courseId', isEqualTo: courseId);
    }

    return query.snapshots().map((snap) {
      final attempts = snap.docs.map(QuizAttemptModel.fromDoc).toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return attempts;
    });
  }

  Future<List<QuizAttemptModel>> getQuizAttempts(
    String uid, {
    String? quizId,
    String? courseId,
    int? limit,
  }) async {
    if (uid.isEmpty) return const [];

    Query<Map<String, dynamic>> query = _userQuizAttempts(uid);
    if (quizId != null && quizId.isNotEmpty) {
      query = query.where('quizId', isEqualTo: quizId);
    } else if (courseId != null && courseId.isNotEmpty) {
      query = query.where('courseId', isEqualTo: courseId);
    }

    final snap = await query.get();
    final attempts = snap.docs.map(QuizAttemptModel.fromDoc).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    if (limit != null && limit > 0 && attempts.length > limit) {
      return attempts.sublist(0, limit);
    }
    return attempts;
  }

  /*
  Purpose:
  Return the user's highest-scoring attempt for a given quiz.

  Response:
  Best QuizAttemptModel or null when no attempts exist.

  Business Rules:
  - Tie-breaker: most recent completedAt wins.
  - Only attempts for the specified quizId are considered.

  Flow:
  1. Fetch attempts filtered by quizId.
  2. Sort by score desc, then completedAt desc.
  3. Return first item or null.

  Side Effects:
  - One Firestore read query.

  Failure Cases:
  - Firestore read errors bubble to caller.
  */
  Future<QuizAttemptModel?> bestAttemptForQuiz(
    String uid,
    String quizId,
  ) async {
    final attempts = await getQuizAttempts(uid, quizId: quizId);
    if (attempts.isEmpty) return null;

    attempts.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.completedAt.compareTo(a.completedAt);
    });
    return attempts.first;
  }

  Future<bool> hasPassedQuiz(String uid, String quizId) async {
    final best = await bestAttemptForQuiz(uid, quizId);
    return best?.passed ?? false;
  }
}
