import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/course_model.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';
import '../../../../shared/widgets/streak_badge.dart';

class SyllabusCourseCard extends ConsumerWidget {
  const SyllabusCourseCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  final CourseModel course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(courseProgressSummaryProvider(course.id));
    final hasCover = course.coverImageUrl.trim().isNotEmpty;

    return CardContainer(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg.r)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: hasCover
                  ? Image.network(
                      course.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _CoverFallback(title: course.title),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const _CoverFallback();
                      },
                    )
                  : _CoverFallback(title: course.title),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                if (course.tags.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    course.tags.take(2).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontSize: 10.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                if (summary.isEnrolled && summary.totalLessons > 0) ...[
                  SizedBox(height: 8.h),
                  ScoreBar(value: summary.completionFraction, height: 4),
                  SizedBox(height: 4.h),
                  Text(
                    summary.isCourseCompleted
                        ? l10n.syllabusCourseCompleted
                        : l10n.syllabusProgressLabel(
                            summary.completedLessonCount,
                            summary.totalLessons,
                          ),
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontSize: 10.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else if (summary.isEnrolled) ...[
                  SizedBox(height: 8.h),
                  Pill(
                    text: l10n.syllabusEnrolled,
                    color: AppColors.success.withValues(alpha: 0.15),
                    textColor: AppColors.success,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBorder,
      alignment: Alignment.center,
      child: Icon(
        Icons.menu_book_outlined,
        size: 32.r,
        color: AppColors.gold.withValues(alpha: 0.5),
      ),
    );
  }
}
