import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/quiz_model.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/streak_badge.dart';
import 'admin_shared_widgets.dart';

class AdminQuestionTile extends StatelessWidget {
  const AdminQuestionTile({
    super.key,
    required this.question,
    required this.index,
    required this.onTap,
    required this.onDismissed,
  });

  final QuizQuestion question;
  final int index;
  final VoidCallback onTap;
  final Future<void> Function() onDismissed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final optionCount = question.options.length;
    final correctLabel = question.correctIndex >= 0 &&
            question.correctIndex < question.options.length
        ? question.options[question.correctIndex]
        : '';

    return Padding(
      key: ValueKey<String>(question.id),
      padding: EdgeInsets.only(bottom: 8.h),
      child: Dismissible(
        key: ValueKey<String>('dismiss-${question.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.delete,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 6.w),
              Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
            ],
          ),
        ),
        confirmDismiss: (_) async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.emeraldDeep,
              title: Text(
                l10n.adminQuizQuestionDeleteTitle,
                style: AppTextStyles.headlineMedium(ctx),
              ),
              content: Text(
                l10n.adminDeleteConfirm,
                style: AppTextStyles.bodyMedium(ctx),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    l10n.delete,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          );
          return confirmed ?? false;
        },
        onDismissed: (_) => onDismissed(),
        child: CardContainer(
          onTap: onTap,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: AppColors.textMuted,
                  size: 22.r,
                ),
              ),
              SizedBox(width: 8.w),
              AdminIconBox(icon: Icons.quiz_outlined),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (correctLabel.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        l10n.adminQuizCorrectAnswer(correctLabel),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          fontSize: 11.sp,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Pill(
                text: l10n.adminQuizOptionCount(optionCount),
                color: AppColors.cardBorder,
                textColor: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
