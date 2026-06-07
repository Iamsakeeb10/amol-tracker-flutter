import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/husna_name_model.dart';
import '../../../../providers/asma_ul_husna_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../widgets/husna_quiz_option.dart';

class AsmaUlHusnaQuizScreen extends ConsumerWidget {
  const AsmaUlHusnaQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(asmaUlHusnaProvider);
    final notifier = ref.read(asmaUlHusnaProvider.notifier);

    if (state.quizFinished) {
      return _QuizFinishedView(
        score: state.quizScore,
        total: state.quizTotal,
        onRetry: () {
          notifier.resetQuiz();
          notifier.startQuiz();
        },
      );
    }

    final question = state.currentQuestion;
    if (question == null) {
      return AppScaffold(
        handleExitBack: false,
        appBar: AppBar(
          title: Text(l10n.husnaQuiz, style: AppTextStyles.headlineMedium(context)),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final meaning =
        question.localizedMeaningFromLocale(Localizations.localeOf(context));
    final answered = state.selectedAnswer;
    final correctNumber = question.number;

    return AppScaffold(
      handleExitBack: false,
      appBar: AppBar(
        title: Text(l10n.husnaQuiz, style: AppTextStyles.headlineMedium(context)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        children: [
          Text(
            l10n.husnaQuizScore(state.quizScore, state.quizTotal),
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.husnaQuizQuestion,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  meaning,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          ...state.quizOptions.map((option) {
            final optionState = _resolveOptionState(
              option: option,
              answered: answered,
              correctNumber: correctNumber,
              showResult: state.showAnswerResult,
            );
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: HusnaQuizOption(
                name: option,
                state: optionState,
                enabled: !state.showAnswerResult,
                onTap: () => notifier.selectQuizAnswer(option),
              ),
            );
          }),
          if (state.showAnswerResult) ...[
            SizedBox(height: 4.h),
            Center(
              child: Text(
                answered?.number == correctNumber
                    ? l10n.husnaQuizCorrect
                    : l10n.husnaQuizWrong,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: answered?.number == correctNumber
                      ? AppColors.success
                      : AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: notifier.nextQuizQuestion,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: Text(
                  l10n.husnaNextQuestion,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.emeraldDeep,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  HusnaQuizOptionState _resolveOptionState({
    required HusnaName option,
    required HusnaName? answered,
    required int correctNumber,
    required bool showResult,
  }) {
    if (!showResult || answered == null) return HusnaQuizOptionState.idle;
    if (option.number == correctNumber) return HusnaQuizOptionState.correct;
    if (option.number == answered.number) return HusnaQuizOptionState.wrong;
    return HusnaQuizOptionState.idle;
  }
}

class _QuizFinishedView extends StatelessWidget {
  const _QuizFinishedView({
    required this.score,
    required this.total,
    required this.onRetry,
  });

  final int score;
  final int total;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      handleExitBack: false,
      appBar: AppBar(
        title: Text(l10n.husnaQuiz, style: AppTextStyles.headlineMedium(context)),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, color: AppColors.gold, size: 64.r),
            SizedBox(height: 16.h),
            Text(
              l10n.husnaQuizFinished,
              style: AppTextStyles.headlineMedium(context),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.husnaQuizScore(score, total),
              style: AppTextStyles.bodyLarge(context).copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: Text(
                  l10n.husnaRetryQuiz,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.emeraldDeep,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
