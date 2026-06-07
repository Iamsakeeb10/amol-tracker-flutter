import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/quiz_model.dart';
import '../../../../providers/quiz_provider.dart';
import '../../../../shared/widgets/card_container.dart';

class SyllabusQuizTile extends ConsumerWidget {
  const SyllabusQuizTile({
    super.key,
    required this.courseId,
    required this.quiz,
    this.onTap,
  });

  final String courseId;
  final QuizModel quiz;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final progress = ref.watch(
      quizProgressProvider((courseId: courseId, quizId: quiz.id)),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: CardContainer(
        onTap: onTap,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.goldCard,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.quiz_outlined,
                size: 20.r,
                color: AppColors.gold,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    l10n.syllabusQuizQuestionCount(quiz.questionCount),
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontSize: 11.sp,
                    ),
                  ),
                  if (progress.attemptCount > 0) ...[
                    SizedBox(height: 4.h),
                    Text(
                      progress.bestAttempt == null
                          ? l10n.syllabusQuizAttemptCount(progress.attemptCount)
                          : l10n.syllabusQuizAttemptsLabel(
                              progress.attemptCount,
                              progress.bestAttempt!.score,
                              progress.bestAttempt!.totalQuestions,
                            ),
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 11.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  if (progress.hasPassed) ...[
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 16.r,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            l10n.syllabusQuizAlreadyPassed,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall(context).copyWith(
                              fontSize: 11.sp,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 22.r,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
