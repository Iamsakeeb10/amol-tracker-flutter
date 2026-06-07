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
import '../../../../shared/widgets/section_header.dart';
import '../widgets/quiz_helpers.dart';
import '../widgets/quiz_review_tile.dart';

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({
    super.key,
    required this.courseId,
    required this.quizId,
  });

  final String courseId;
  final String quizId;

  QuizRef get _quizRef => (courseId: courseId, quizId: quizId);

  String _message(AppLocalizations l10n, int score, int total, bool passed) {
    if (passed) return l10n.syllabusQuizResultPassed;
    if (total <= 0) return l10n.syllabusQuizKeepLearning;
    final pct = score / total;
    if (pct >= 0.8) return l10n.syllabusQuizExcellent;
    if (pct >= 0.5) return l10n.syllabusQuizGoodEffort;
    return l10n.syllabusQuizKeepLearning;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(quizSessionProvider(_quizRef));
    final attempt = session.submittedAttempt;
    final quiz = session.quiz;

    if (!session.sessionFinished || attempt == null || quiz == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(AppRoutes.quizIntroPath(courseId, quizId));
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final percent = attempt.totalQuestions > 0
        ? ((attempt.score / attempt.totalQuestions) * 100).round()
        : 0;
    final passed = attempt.passed;

    return AppScaffold(
      handleExitBack: false,
      padding: EdgeInsets.zero,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          l10n.syllabusQuizResultTitle,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        children: [
          Column(
            children: [
              AnimatedScale(
                scale: 1,
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                child: Icon(
                  passed ? Icons.emoji_events_outlined : Icons.replay_outlined,
                  color: passed ? AppColors.gold : AppColors.textSecondary,
                  size: 64.r,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                passed
                    ? l10n.syllabusQuizResultPassed
                    : l10n.syllabusQuizResultFailed,
                style: AppTextStyles.headlineMedium(context).copyWith(
                  color: passed ? AppColors.success : AppColors.danger,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                '$percent%',
                style: AppTextStyles.goldNumeric(context).copyWith(fontSize: 36.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                l10n.syllabusQuizYourScore(attempt.score, attempt.totalQuestions),
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (session.submittedAttemptNumber != null) ...[
                SizedBox(height: 6.h),
                Text(
                  l10n.syllabusQuizAttemptNumber(session.submittedAttemptNumber!),
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              if (attempt.timeTakenSeconds > 0) ...[
                SizedBox(height: 6.h),
                Text(
                  l10n.syllabusQuizTimeTaken(
                    formatQuizDuration(attempt.timeTakenSeconds),
                  ),
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              SizedBox(height: 8.h),
              Text(
                _message(l10n, attempt.score, attempt.totalQuestions, passed),
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          SizedBox(height: 24.h),
          SectionHeader(title: l10n.syllabusQuizReviewSection),
          SizedBox(height: 8.h),
          ...List.generate(quiz.questions.length, (index) {
            final selected = index < attempt.answers.length
                ? attempt.answers[index]
                : -1;
            return QuizReviewTile(
              index: index,
              question: quiz.questions[index],
              selectedIndex: selected,
            );
          }),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ref.read(quizSessionProvider(_quizRef).notifier).resetSession();
                context.go(AppRoutes.quizIntroPath(courseId, quizId));
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.emeraldDeep,
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              child: Text(
                l10n.syllabusQuizRetry,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.emeraldDeep,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(AppRoutes.courseDetailPath(courseId)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: BorderSide(color: AppColors.goldBorder),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              child: Text(l10n.syllabusQuizBackToCourse),
            ),
          ),
        ],
      ),
    );
  }
}
