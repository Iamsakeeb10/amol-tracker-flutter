import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../admin/presentation/widgets/admin_course_helpers.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/lesson_model.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/streak_badge.dart';

class SyllabusLessonTile extends StatelessWidget {
  const SyllabusLessonTile({
    super.key,
    required this.lesson,
    required this.index,
    required this.isEnrolled,
    required this.isCompleted,
    this.onTap,
  });

  final LessonModel lesson;
  final int index;
  final bool isEnrolled;
  final bool isCompleted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: CardContainer(
        onTap: onTap,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            _LessonIndexBadge(
              index: index + 1,
              isCompleted: isEnrolled && isCompleted,
            ),
            SizedBox(width: 12.w),
            Icon(
              iconForResourceType(lesson.resourceType),
              size: 20.r,
              color: AppColors.goldLight,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    resourceTypeLabel(l10n, lesson.resourceType),
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            if (lesson.durationMinutes > 0) ...[
              Pill(
                text: '${lesson.durationMinutes}m',
                color: AppColors.cardBorder,
                textColor: AppColors.textSecondary,
              ),
              SizedBox(width: 8.w),
            ],
            if (isEnrolled && isCompleted)
              Icon(Icons.check_circle, color: AppColors.success, size: 20.r)
            else if (isEnrolled)
              Icon(
                Icons.radio_button_unchecked,
                color: AppColors.textMuted,
                size: 20.r,
              ),
          ],
        ),
      ),
    );
  }
}

class _LessonIndexBadge extends StatelessWidget {
  const _LessonIndexBadge({
    required this.index,
    required this.isCompleted,
  });

  final int index;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28.r,
      height: 28.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.cardBorder,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted ? AppColors.success : AppColors.cardBorder,
        ),
      ),
      child: Text(
        '$index',
        style: AppTextStyles.pill(context).copyWith(
          fontSize: 11.sp,
          color: isCompleted ? AppColors.success : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
