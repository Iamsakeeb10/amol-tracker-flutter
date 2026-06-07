import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';
import 'lms_xp_widgets.dart';

class CourseProgressHeader extends ConsumerWidget {
  const CourseProgressHeader({
    super.key,
    required this.courseId,
    required this.onEnroll,
    required this.isEnrolling,
  });

  final String courseId;
  final VoidCallback onEnroll;
  final bool isEnrolling;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(courseProgressSummaryProvider(courseId));
    final lmsXp = ref.watch(currentUserProvider).asData?.value?.lmsXp ?? 0;

    return CardContainer(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (summary.isEnrolled && summary.totalLessons > 0) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    summary.isCourseCompleted
                        ? l10n.syllabusCourseCompleted
                        : l10n.syllabusProgressLabel(
                            summary.completedLessonCount,
                            summary.totalLessons,
                          ),
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${summary.completionPercent}%',
                  style: AppTextStyles.goldNumeric(context).copyWith(
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerLeft,
              child: LmsLevelCompactChip(lmsXp: lmsXp),
            ),
            SizedBox(height: 10.h),
            ScoreBar(value: summary.completionFraction, height: 6),
          ] else if (summary.isEnrolled) ...[
            Text(
              l10n.syllabusEnrolled,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ] else ...[
            Text(
              l10n.syllabusEnrollPrompt,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isEnrolling ? null : onEnroll,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  disabledBackgroundColor: AppColors.cardBorder,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                icon: isEnrolling
                    ? SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.emeraldDeep,
                        ),
                      )
                    : Icon(Icons.school_outlined, size: 18.r),
                label: Text(
                  l10n.syllabusEnroll,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.emeraldDeep,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
