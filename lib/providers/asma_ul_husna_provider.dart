import 'dart:math';

import 'package:riverpod/legacy.dart';

import '../core/constants/asma_ul_husna.dart';
import '../core/services/local_storage_service.dart';
import '../models/husna_name_model.dart';

const int kHusnaQuizMinLearned = 4;
const int kHusnaQuizQuestionCount = 10;

class AsmaUlHusnaState {
  const AsmaUlHusnaState({
    required this.learnedNumbers,
    required this.isLoading,
    required this.quizScore,
    required this.quizTotal,
    required this.quizFinished,
    required this.currentQuestion,
    required this.quizOptions,
    required this.selectedAnswer,
    required this.showAnswerResult,
  });

  factory AsmaUlHusnaState.initial() {
    return const AsmaUlHusnaState(
      learnedNumbers: <int>{},
      isLoading: true,
      quizScore: 0,
      quizTotal: 0,
      quizFinished: false,
      currentQuestion: null,
      quizOptions: <HusnaName>[],
      selectedAnswer: null,
      showAnswerResult: false,
    );
  }

  final Set<int> learnedNumbers;
  final bool isLoading;
  final int quizScore;
  final int quizTotal;
  final bool quizFinished;
  final HusnaName? currentQuestion;
  final List<HusnaName> quizOptions;
  final HusnaName? selectedAnswer;
  final bool showAnswerResult;

  int get learnedCount => learnedNumbers.length;

  double get learnedProgress =>
      kHusnaTotalCount <= 0 ? 0 : learnedCount / kHusnaTotalCount;

  bool get canStartQuiz => learnedCount >= kHusnaQuizMinLearned;

  bool isLearned(int number) => learnedNumbers.contains(number);

  AsmaUlHusnaState copyWith({
    Set<int>? learnedNumbers,
    bool? isLoading,
    int? quizScore,
    int? quizTotal,
    bool? quizFinished,
    HusnaName? currentQuestion,
    List<HusnaName>? quizOptions,
    HusnaName? selectedAnswer,
    bool? showAnswerResult,
    bool clearQuestion = false,
    bool clearSelectedAnswer = false,
  }) {
    return AsmaUlHusnaState(
      learnedNumbers: learnedNumbers ?? this.learnedNumbers,
      isLoading: isLoading ?? this.isLoading,
      quizScore: quizScore ?? this.quizScore,
      quizTotal: quizTotal ?? this.quizTotal,
      quizFinished: quizFinished ?? this.quizFinished,
      currentQuestion:
          clearQuestion ? null : (currentQuestion ?? this.currentQuestion),
      quizOptions: quizOptions ?? this.quizOptions,
      selectedAnswer:
          clearSelectedAnswer ? null : (selectedAnswer ?? this.selectedAnswer),
      showAnswerResult: showAnswerResult ?? this.showAnswerResult,
    );
  }
}

/*
Purpose:
Track learned Asma ul Husna names locally and run an offline meaning-to-name quiz.

Response:
Immutable [AsmaUlHusnaState] with learned set, loading flag, and active quiz session.

Business Rules:
- Learned numbers persist in Hive under husna_learned.
- Quiz unlocks after at least 4 names are marked learned.
- Quiz asks 10 questions from learned names only.
- Each question shows meaning; user picks one of four transliterations.
- Correct answers increment score; session ends after 10 questions.

Flow:
1. Load learned numbers from Hive on init/refresh.
2. Toggle learned state per name number and persist immediately.
3. Start quiz by shuffling learned names and building first question.
4. On answer, reveal result then advance or finish session.

Side Effects:
- Hive writes when learned set changes.

Failure Cases:
- Empty learned pool blocks quiz start.
- Fewer than 4 learned names keeps quiz locked.
*/
class AsmaUlHusnaNotifier extends StateNotifier<AsmaUlHusnaState> {
  AsmaUlHusnaNotifier() : super(AsmaUlHusnaState.initial()) {
    _load();
  }

  final Random _random = Random();
  List<HusnaName> _quizQueue = const [];

  Future<void> refreshFromStorage() async {
    final learned = LocalStorageService.getHusnaLearnedNumbers();
    state = state.copyWith(learnedNumbers: learned, isLoading: false);
  }

  Future<void> _load() async {
    final learned = LocalStorageService.getHusnaLearnedNumbers();
    state = state.copyWith(learnedNumbers: learned, isLoading: false);
  }

  Future<void> toggleLearned(int number) async {
    if (number < 1 || number > kHusnaTotalCount) return;
    final updated = Set<int>.from(state.learnedNumbers);
    if (updated.contains(number)) {
      updated.remove(number);
    } else {
      updated.add(number);
    }
    state = state.copyWith(learnedNumbers: updated);
    await LocalStorageService.saveHusnaLearnedNumbers(updated);
  }

  bool startQuiz() {
    if (!state.canStartQuiz) return false;
    final learnedNames = kAsmaUlHusna
        .where((n) => state.learnedNumbers.contains(n.number))
        .toList();
    if (learnedNames.length < kHusnaQuizMinLearned) return false;
    learnedNames.shuffle(_random);
    final questionCount = learnedNames.length < kHusnaQuizQuestionCount
        ? learnedNames.length
        : kHusnaQuizQuestionCount;
    _quizQueue = learnedNames.take(questionCount).toList();
    state = state.copyWith(
      quizScore: 0,
      quizTotal: _quizQueue.length,
      quizFinished: false,
      showAnswerResult: false,
      clearSelectedAnswer: true,
    );
    _setQuestion(_quizQueue.first);
    return true;
  }

  void _setQuestion(HusnaName question) {
    final distractors = kAsmaUlHusna
        .where((n) => n.number != question.number)
        .toList()
      ..shuffle(_random);
    final options = <HusnaName>[question, ...distractors.take(3)]
      ..shuffle(_random);
    state = state.copyWith(
      currentQuestion: question,
      quizOptions: options,
      showAnswerResult: false,
      clearSelectedAnswer: true,
    );
  }

  void selectQuizAnswer(HusnaName answer) {
    if (state.showAnswerResult || state.quizFinished) return;
    final question = state.currentQuestion;
    if (question == null) return;
    final isCorrect = answer.number == question.number;
    state = state.copyWith(
      selectedAnswer: answer,
      showAnswerResult: true,
      quizScore: isCorrect ? state.quizScore + 1 : state.quizScore,
    );
  }

  void nextQuizQuestion() {
    if (!state.showAnswerResult || state.quizFinished) return;
    final current = state.currentQuestion;
    if (current == null) return;
    final currentIndex = _quizQueue.indexWhere((n) => n.number == current.number);
    final isLast = currentIndex < 0 || currentIndex >= _quizQueue.length - 1;
    if (isLast) {
      state = state.copyWith(
        quizFinished: true,
        clearQuestion: true,
        quizOptions: const [],
        showAnswerResult: false,
        clearSelectedAnswer: true,
      );
      return;
    }
    _setQuestion(_quizQueue[currentIndex + 1]);
  }

  void resetQuiz() {
    _quizQueue = const [];
    state = state.copyWith(
      quizScore: 0,
      quizTotal: 0,
      quizFinished: false,
      clearQuestion: true,
      quizOptions: const [],
      showAnswerResult: false,
      clearSelectedAnswer: true,
    );
  }
}

final asmaUlHusnaProvider =
    StateNotifierProvider<AsmaUlHusnaNotifier, AsmaUlHusnaState>(
  (ref) => AsmaUlHusnaNotifier(),
);
