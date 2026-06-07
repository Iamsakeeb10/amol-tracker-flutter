import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/quiz_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';
import '../widgets/quiz_helpers.dart';
import '../widgets/quiz_option_tile.dart';
import '../widgets/quiz_timer_bar.dart';

class QuizQuestionScreen extends ConsumerStatefulWidget {
  const QuizQuestionScreen({
    super.key,
    required this.courseId,
    required this.quizId,
  });

  final String courseId;
  final String quizId;

  @override
  ConsumerState<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends ConsumerState<QuizQuestionScreen> {
  final _timerKey = GlobalKey<QuizTimerBarState>();
  var _isSubmitting = false;
  var _timeExpired = false;

  QuizRef get _quizRef => (courseId: widget.courseId, quizId: widget.quizId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(quizSessionProvider(_quizRef));
    final notifier = ref.read(quizSessionProvider(_quizRef).notifier);

    ref.listen(quizSessionProvider(_quizRef), (prev, next) {
      if (next.sessionFinished && next.submittedAttempt != null) {
        context.pushReplacement(AppRoutes.quizResultPath(
          widget.courseId,
          widget.quizId,
        ));
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    if (!session.sessionStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(AppRoutes.quizIntroPath(widget.courseId, widget.quizId));
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (session.isLoading || session.quiz == null) {
      return AppScaffold(
        handleExitBack: false,
        appBar: AppBar(
          title: Text(l10n.syllabusQuizTitle, style: AppTextStyles.headlineMedium(context)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final quiz = session.quiz!;
    if (quiz.questions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(AppRoutes.quizIntroPath(widget.courseId, widget.quizId));
      });
      return AppScaffold(
        handleExitBack: false,
        appBar: AppBar(
          title: Text(l10n.syllabusQuizTitle, style: AppTextStyles.headlineMedium(context)),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              l10n.syllabusQuizNotReady,
              style: AppTextStyles.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final safeIndex = session.currentQuestionIndex.clamp(
      0,
      quiz.questions.length - 1,
    );
    if (safeIndex != session.currentQuestionIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        notifier.goToQuestion(safeIndex);
      });
      return AppScaffold(
        handleExitBack: false,
        appBar: AppBar(
          title: Text(
            quiz.title,
            style: AppTextStyles.headlineMedium(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final question = quiz.questions[safeIndex];
    final current = safeIndex + 1;
    final selected = session.currentAnswer;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmExit(context, l10n);
        if (leave && context.mounted) context.pop();
      },
      child: AppScaffold(
        handleExitBack: false,
        padding: EdgeInsets.zero,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.close, size: 22.r),
            onPressed: () async {
              final leave = await _confirmExit(context, l10n);
              if (leave && context.mounted) context.pop();
            },
          ),
          title: Text(
            quiz.title,
            style: AppTextStyles.headlineMedium(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          children: [
            if (quiz.timeLimitSeconds > 0)
              QuizTimerBar(
                key: _timerKey,
                totalSeconds: quiz.timeLimitSeconds,
                onExpired: () => _handleTimeUp(l10n),
              ),
            if (quiz.timeLimitSeconds > 0) SizedBox(height: 16.h),
            Text(
              l10n.syllabusQuizProgress(current, quiz.questionCount),
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 6.h),
            ScoreBar(
              value: quizProgressValue(
                safeIndex,
                quiz.questionCount,
              ),
              height: 6,
            ),
            SizedBox(height: 16.h),
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.syllabusQuizQuestionLabel,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    question.text,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            ...List.generate(question.options.length, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: QuizOptionTile(
                  index: index,
                  label: question.options[index],
                  state: selected == index
                      ? QuizOptionTileState.selected
                      : QuizOptionTileState.idle,
                  enabled: !_isSubmitting && !_timeExpired,
                  onTap: () => notifier.selectAnswer(index),
                ),
              );
            }),
            SizedBox(height: 8.h),
            Row(
              children: [
                if (safeIndex > 0)
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : notifier.previousQuestion,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: BorderSide(color: AppColors.goldBorder),
                    ),
                    child: Text(l10n.syllabusQuizPrevious),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _isSubmitting || _timeExpired
                      ? null
                      : () => _handlePrimaryAction(l10n, session, notifier),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 18.r,
                          height: 18.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.emeraldDeep,
                          ),
                        )
                      : Text(
                          session.isLastQuestion
                              ? l10n.syllabusQuizSubmit
                              : l10n.syllabusQuizNext,
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.emeraldDeep,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePrimaryAction(
    AppLocalizations l10n,
    QuizSessionState session,
    QuizSessionNotifier notifier,
  ) async {
    if (session.isLastQuestion) {
      await _submitQuiz(l10n);
      return;
    }
    notifier.nextQuestion();
  }

  Future<void> _handleTimeUp(AppLocalizations l10n) async {
    if (_timeExpired || _isSubmitting) return;
    setState(() => _timeExpired = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.syllabusQuizTimeUp)),
    );
    await _submitQuiz(l10n);
  }

  Future<void> _submitQuiz(AppLocalizations l10n) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final elapsed = _timerKey.currentState?.elapsedSeconds ?? 0;
    final quiz = ref.read(quizSessionProvider(_quizRef)).quiz;
    final timeTaken = quiz != null && quiz.timeLimitSeconds > 0
        ? elapsed.clamp(0, quiz.timeLimitSeconds)
        : elapsed;

    await ref
        .read(quizSessionProvider(_quizRef).notifier)
        .submit(timeTakenSeconds: timeTaken);

    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<bool> _confirmExit(BuildContext context, AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.emeraldDeep,
        title: Text(
          l10n.syllabusQuizConfirmExitTitle,
          style: AppTextStyles.headlineMedium(context),
        ),
        content: Text(
          l10n.syllabusQuizConfirmExitMessage,
          style: AppTextStyles.bodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.emeraldDeep,
            ),
            child: Text(l10n.syllabusQuizLeave),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
