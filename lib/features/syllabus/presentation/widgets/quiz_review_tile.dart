import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/quiz_model.dart';
import '../../../../shared/widgets/card_container.dart';
import 'quiz_option_tile.dart';

class QuizReviewTile extends StatelessWidget {
  const QuizReviewTile({
    super.key,
    required this.index,
    required this.question,
    required this.selectedIndex,
  });

  final int index;
  final QuizQuestion question;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCorrect = selectedIndex == question.correctIndex;
    final hasAnswer = selectedIndex >= 0 && selectedIndex < question.options.length;

    return CardContainer(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 18.r,
                color: isCorrect ? AppColors.success : AppColors.danger,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  l10n.syllabusQuizReviewQuestion(index + 1),
                  style: AppTextStyles.label(context).copyWith(
                    color: isCorrect ? AppColors.success : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            question.text,
            style: AppTextStyles.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasAnswer) ...[
            SizedBox(height: 10.h),
            Text(
              l10n.syllabusQuizYourAnswer,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 6.h),
            QuizOptionTile(
              index: selectedIndex,
              label: question.options[selectedIndex],
              state: isCorrect
                  ? QuizOptionTileState.correct
                  : QuizOptionTileState.wrong,
              enabled: false,
              onTap: () {},
            ),
          ],
          if (!isCorrect) ...[
            SizedBox(height: 10.h),
            Text(
              l10n.syllabusQuizCorrectAnswer,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 6.h),
            QuizOptionTile(
              index: question.correctIndex,
              label: question.options[question.correctIndex],
              state: QuizOptionTileState.correct,
              enabled: false,
              onTap: () {},
            ),
          ],
          if (question.explanation.trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              l10n.syllabusQuizExplanation,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              question.explanation,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
