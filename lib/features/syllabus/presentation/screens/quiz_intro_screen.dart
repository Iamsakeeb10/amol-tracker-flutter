import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/quiz_attempt_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/quiz_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../widgets/quiz_helpers.dart';

class QuizIntroScreen extends ConsumerWidget {
  const QuizIntroScreen({
    super.key,
    required this.courseId,
    required this.quizId,
  });

  final String courseId;
  final String quizId;

  QuizRef get _quizRef => (courseId: courseId, quizId: quizId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(quizSessionProvider(_quizRef));
    final progress = ref.watch(quizProgressProvider(_quizRef));

    return AppScaffold(
      handleExitBack: false,
      padding: EdgeInsets.zero,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.courseDetailPath(courseId));
            }
          },
        ),
        title: Text(
          session.quiz?.title ?? l10n.syllabusQuizTitle,
          style: AppTextStyles.headlineMedium(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(context, ref, l10n, session, progress),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    QuizSessionState session,
    QuizProgressInfo progress,
  ) {
    if (session.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (session.error != null || session.quiz == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            session.error ?? l10n.syllabusQuizLoadFailed,
            style: AppTextStyles.bodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final quiz = session.quiz!;
    final canStart = quiz.questionCount > 0;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      children: [
        CardContainer.gold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.syllabusQuizRulesTitle,
                style: AppTextStyles.label(context).copyWith(
                  color: AppColors.gold,
                ),
              ),
              SizedBox(height: 12.h),
              _RuleRow(
                icon: Icons.quiz_outlined,
                label: l10n.syllabusQuizQuestionCount(quiz.questionCount),
              ),
              SizedBox(height: 8.h),
              _RuleRow(
                icon: Icons.timer_outlined,
                label: l10n.syllabusQuizTimeLimitLabel(
                  formatQuizTimeLimit(l10n, quiz.timeLimitSeconds),
                ),
              ),
              SizedBox(height: 8.h),
              _RuleRow(
                icon: Icons.verified_outlined,
                label: l10n.syllabusQuizPassingScoreLabel(quiz.passingScore),
              ),
            ],
          ),
        ),
        if (progress.attemptCount > 0) ...[
          SizedBox(height: 16.h),
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.syllabusQuizPreviousAttempts,
                  style: AppTextStyles.label(context),
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.syllabusQuizAttemptCount(progress.attemptCount),
                  style: AppTextStyles.bodyMedium(context),
                ),
                if (progress.bestAttempt != null) ...[
                  SizedBox(height: 6.h),
                  Text(
                    l10n.syllabusQuizBestScore(
                      progress.bestAttempt!.score,
                      progress.bestAttempt!.totalQuestions,
                    ),
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (progress.hasPassed) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 18.r),
                      SizedBox(width: 6.w),
                      Text(
                        l10n.syllabusQuizAlreadyPassed,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 12.h),
                ...() {
                  final sorted = List<QuizAttemptModel>.from(progress.attempts)
                    ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
                  return sorted.map(
                    (attempt) => _AttemptHistoryRow(
                      attempt: attempt,
                      l10n: l10n,
                    ),
                  );
                }(),
              ],
            ),
          ),
        ],
        SizedBox(height: 24.h),
        if (!canStart) ...[
          Text(
            l10n.syllabusQuizNotReady,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: canStart ? () => _handleStart(context, ref, l10n) : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.emeraldDeep,
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
            child: Text(
              l10n.syllabusQuizStart,
              style: AppTextStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.emeraldDeep,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleStart(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      context.push(AppRoutes.signIn);
      return;
    }

    final quiz = ref.read(quizSessionProvider(_quizRef)).quiz;
    if (quiz == null || quiz.questionCount == 0) return;

    ref.read(quizSessionProvider(_quizRef).notifier).startSession();
    context.push(AppRoutes.quizPlayPath(courseId, quizId));
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18.r, color: AppColors.goldLight),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
      ],
    );
  }
}

class _AttemptHistoryRow extends StatelessWidget {
  const _AttemptHistoryRow({
    required this.attempt,
    required this.l10n,
  });

  final QuizAttemptModel attempt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final statusColor = attempt.passed ? AppColors.success : AppColors.danger;
    final statusLabel = attempt.passed
        ? l10n.syllabusQuizAttemptPassed
        : l10n.syllabusQuizAttemptFailed;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.syllabusQuizAttemptHistoryRow(
                attempt.score,
                attempt.totalQuestions,
                formatQuizAttemptDate(attempt.completedAt),
              ),
              style: AppTextStyles.bodySmall(context),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              statusLabel,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
