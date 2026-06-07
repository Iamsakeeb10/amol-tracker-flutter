import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/services/quiz_service.dart';
import '../core/services/lms_xp_service.dart';
import '../models/quiz_attempt_model.dart';
import '../models/quiz_model.dart';
import 'auth_provider.dart';
import 'lms_level_celebration_provider.dart';

final quizServiceProvider = Provider<QuizService>((ref) => QuizService());

typedef QuizRef = ({String courseId, String quizId});

typedef LessonQuizzesRef = ({String courseId, String lessonId});

final quizProvider = StreamProvider.family<QuizModel?, QuizRef>((ref, refKey) {
  return ref
      .read(quizServiceProvider)
      .quizStream(refKey.courseId, refKey.quizId);
});

final courseQuizzesProvider =
    StreamProvider.family<List<QuizModel>, String>((ref, courseId) {
  return ref.read(quizServiceProvider).quizzesForCourseStream(courseId);
});

final lessonQuizzesProvider =
    StreamProvider.family<List<QuizModel>, LessonQuizzesRef>((ref, refKey) {
  return ref.read(quizServiceProvider).quizzesForLessonStream(
        refKey.courseId,
        refKey.lessonId,
      );
});

final courseLevelQuizzesProvider =
    StreamProvider.family<List<QuizModel>, String>((ref, courseId) {
  return ref.read(quizServiceProvider).courseLevelQuizzesStream(courseId);
});

final userQuizAttemptsProvider =
    StreamProvider.family<List<QuizAttemptModel>, QuizRef>((ref, refKey) {
  final uid = ref.watch(currentUserProvider).asData?.value?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream<List<QuizAttemptModel>>.value(const []);
  }
  return ref.read(quizServiceProvider).quizAttemptsStream(
        uid,
        quizId: refKey.quizId,
      );
});

class QuizProgressInfo {
  const QuizProgressInfo({
    required this.attempts,
    required this.bestAttempt,
    required this.hasPassed,
  });

  factory QuizProgressInfo.empty() {
    return const QuizProgressInfo(
      attempts: [],
      bestAttempt: null,
      hasPassed: false,
    );
  }

  final List<QuizAttemptModel> attempts;
  final QuizAttemptModel? bestAttempt;
  final bool hasPassed;

  int get attemptCount => attempts.length;
}

/*
Purpose:
Summarize a user's quiz history for intro/result screens.

Response:
QuizProgressInfo with attempts, best score, and pass flag.

Business Rules:
- Best attempt: highest score, tie-break by most recent completedAt.
- hasPassed true when any attempt passed or bestAttempt.passed is true.

Flow:
1. Watch live attempts stream for the quiz.
2. Sort by score desc then date desc.
3. Derive bestAttempt and hasPassed.

Side Effects:
  None — read-only derivation.

Failure Cases:
- No attempts yields empty info with hasPassed false.
*/
final quizProgressProvider = Provider.family<QuizProgressInfo, QuizRef>(
  (ref, refKey) {
    final attempts =
        ref.watch(userQuizAttemptsProvider(refKey)).value ?? const [];
    if (attempts.isEmpty) return QuizProgressInfo.empty();

    final sorted = List<QuizAttemptModel>.from(attempts)
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return b.completedAt.compareTo(a.completedAt);
      });

    final best = sorted.first;
    final passed = sorted.any((attempt) => attempt.passed);

    return QuizProgressInfo(
      attempts: attempts,
      bestAttempt: best,
      hasPassed: passed,
    );
  },
);

class QuizSessionState {
  const QuizSessionState({
    this.quiz,
    this.isLoading = false,
    this.error,
    this.currentQuestionIndex = 0,
    this.answers = const [],
    this.isSubmitting = false,
    this.submittedAttempt,
    this.submittedAttemptNumber,
    this.sessionStarted = false,
    this.sessionFinished = false,
  });

  final QuizModel? quiz;
  final bool isLoading;
  final String? error;
  final int currentQuestionIndex;
  final List<int> answers;
  final bool isSubmitting;
  final QuizAttemptModel? submittedAttempt;
  final int? submittedAttemptNumber;
  final bool sessionStarted;
  final bool sessionFinished;

  bool get hasQuiz => quiz != null;

  int get questionCount => quiz?.questionCount ?? 0;

  bool get isLastQuestion =>
      quiz != null && currentQuestionIndex >= quiz!.questions.length - 1;

  int? get currentAnswer {
    if (currentQuestionIndex < 0 || currentQuestionIndex >= answers.length) {
      return null;
    }
    final value = answers[currentQuestionIndex];
    return value < 0 ? null : value;
  }

  QuizSessionState copyWith({
    QuizModel? quiz,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? currentQuestionIndex,
    List<int>? answers,
    bool? isSubmitting,
    QuizAttemptModel? submittedAttempt,
    bool clearSubmittedAttempt = false,
    int? submittedAttemptNumber,
    bool clearSubmittedAttemptNumber = false,
    bool? sessionStarted,
    bool? sessionFinished,
  }) {
    return QuizSessionState(
      quiz: quiz ?? this.quiz,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittedAttempt: clearSubmittedAttempt
          ? null
          : (submittedAttempt ?? this.submittedAttempt),
      submittedAttemptNumber: clearSubmittedAttemptNumber
          ? null
          : (submittedAttemptNumber ?? this.submittedAttemptNumber),
      sessionStarted: sessionStarted ?? this.sessionStarted,
      sessionFinished: sessionFinished ?? this.sessionFinished,
    );
  }
}

/*
Purpose:
Drive an in-app quiz session: load quiz, collect answers, submit attempt.

Response:
QuizSessionState with quiz payload, answer sheet, and submission result.

Business Rules:
- Unanswered questions use -1 internally and count as wrong on submit.
- Session must be started before answering; finished after successful submit.
- Requires signed-in user to persist attempt.

Flow:
1. loadQuiz() fetches quiz by courseId + quizId.
2. startSession() resets index and marks session active.
3. selectAnswer() stores MCQ choice for current question.
4. nextQuestion()/goToQuestion() navigate the answer sheet.
5. submit() scores via QuizService and stores attempt in Firestore.

Side Effects:
- One Firestore write on successful submit.

Failure Cases:
- Missing quiz, auth, or network errors set error and skip finish state.
*/
class QuizSessionNotifier extends StateNotifier<QuizSessionState> {
  QuizSessionNotifier(this._ref, this._quizRef)
      : super(const QuizSessionState()) {
    loadQuiz();
  }

  final Ref _ref;
  final QuizRef _quizRef;

  Future<void> loadQuiz() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final quiz = await _ref.read(quizServiceProvider).getQuiz(
            _quizRef.courseId,
            _quizRef.quizId,
          );
      if (quiz == null) {
        state = state.copyWith(isLoading: false, error: 'Quiz not found.');
        return;
      }
      state = state.copyWith(
        isLoading: false,
        quiz: quiz,
        answers: List<int>.filled(quiz.questions.length, -1),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load this quiz.',
      );
    }
  }

  void startSession() {
    if (state.quiz == null) return;
    state = state.copyWith(
      sessionStarted: true,
      sessionFinished: false,
      currentQuestionIndex: 0,
      submittedAttempt: null,
      clearSubmittedAttempt: true,
      clearSubmittedAttemptNumber: true,
      answers: List<int>.filled(state.quiz!.questions.length, -1),
      clearError: true,
    );
  }

  void selectAnswer(int optionIndex) {
    if (!state.sessionStarted || state.sessionFinished || state.quiz == null) {
      return;
    }
    final updated = List<int>.from(state.answers);
    updated[state.currentQuestionIndex] = optionIndex;
    state = state.copyWith(answers: updated);
  }

  void goToQuestion(int index) {
    final quiz = state.quiz;
    if (!state.sessionStarted || quiz == null) return;
    if (index < 0 || index >= quiz.questions.length) return;
    state = state.copyWith(currentQuestionIndex: index);
  }

  void nextQuestion() {
    if (!state.isLastQuestion) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1);
    }
  }

  Future<bool> submit({required int timeTakenSeconds}) async {
    final quiz = state.quiz;
    if (quiz == null || state.isSubmitting || state.sessionFinished) {
      return false;
    }

    final uid = _ref.read(currentUserProvider).asData?.value?.uid;
    if (uid == null || uid.isEmpty) {
      state = state.copyWith(error: 'Sign in to submit your quiz.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final priorAttempts = await _ref.read(quizServiceProvider).getQuizAttempts(
            uid,
            quizId: quiz.id,
          );
      final hadPassedBefore = priorAttempts.any((a) => a.passed);
      final attemptNumber = priorAttempts.length + 1;
      final attemptId = await _ref.read(quizServiceProvider).submitQuizAttempt(
            uid: uid,
            quiz: quiz,
            answers: state.answers,
            timeTakenSeconds: timeTakenSeconds,
          );
      final attempt =
          await _ref.read(quizServiceProvider).getQuizAttempt(uid, attemptId);
      if (attempt != null && attempt.passed && !hadPassedBefore) {
        try {
          final xpAmount = _ref.read(lmsXpServiceProvider).quizPassXpBonus(
                attempt.score,
                attempt.totalQuestions,
              );
          await awardLmsXpAndCelebrate(_ref, uid: uid, amount: xpAmount);
        } catch (_) {
          // Attempt saved; XP is best-effort.
        }
      }
      state = state.copyWith(
        isSubmitting: false,
        sessionFinished: true,
        submittedAttempt: attempt,
        submittedAttemptNumber: attemptNumber,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to submit quiz. Try again.',
      );
      return false;
    }
  }

  void resetSession() {
    final quiz = state.quiz;
    state = QuizSessionState(
      quiz: quiz,
      answers:
          quiz != null ? List<int>.filled(quiz.questions.length, -1) : const [],
    );
  }
}

final quizSessionProvider = StateNotifierProvider.autoDispose
    .family<QuizSessionNotifier, QuizSessionState, QuizRef>(
  (ref, refKey) => QuizSessionNotifier(ref, refKey),
);
