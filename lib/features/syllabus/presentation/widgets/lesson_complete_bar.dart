import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class LessonCompleteBar extends StatelessWidget {
  const LessonCompleteBar({
    super.key,
    required this.isEnrolled,
    required this.isCompleted,
    required this.isBusy,
    required this.onMarkComplete,
  });

  final bool isEnrolled;
  final bool isCompleted;
  final bool isBusy;
  final VoidCallback onMarkComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.emeraldDeep.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEnrolled)
              Text(
                l10n.syllabusEnrollToComplete,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            if (!isEnrolled) SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !isEnrolled || isCompleted || isBusy
                    ? null
                    : onMarkComplete,
                icon: isBusy
                    ? SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.emeraldDeep,
                        ),
                      )
                    : Icon(
                        isCompleted
                            ? Icons.check_circle_outline
                            : Icons.task_alt_outlined,
                        size: 18.r,
                      ),
                label: Text(
                  isCompleted
                      ? l10n.syllabusLessonCompleted
                      : l10n.syllabusMarkComplete,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCompleted ? AppColors.success : AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  disabledBackgroundColor: AppColors.cardBorder,
                  disabledForegroundColor: AppColors.textMuted,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  textStyle: AppTextStyles.button(context).copyWith(
                    color: AppColors.emeraldDeep,
                    fontWeight: FontWeight.w600,
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
