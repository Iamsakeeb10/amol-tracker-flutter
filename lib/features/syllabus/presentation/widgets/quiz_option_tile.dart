import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import 'quiz_helpers.dart';

enum QuizOptionTileState { idle, selected, correct, wrong }

class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.index,
    required this.label,
    required this.state,
    required this.enabled,
    required this.onTap,
    this.trailing,
  });

  final int index;
  final String label;
  final QuizOptionTileState state;
  final bool enabled;
  final VoidCallback onTap;
  final Widget? trailing;

  Color _backgroundColor() {
    switch (state) {
      case QuizOptionTileState.correct:
        return AppColors.successLight;
      case QuizOptionTileState.wrong:
        return AppColors.dangerLight;
      case QuizOptionTileState.selected:
        return AppColors.goldCard;
      case QuizOptionTileState.idle:
        return AppColors.cardDark;
    }
  }

  Color _borderColor() {
    switch (state) {
      case QuizOptionTileState.correct:
        return AppColors.success;
      case QuizOptionTileState.wrong:
        return AppColors.danger;
      case QuizOptionTileState.selected:
        return AppColors.gold;
      case QuizOptionTileState.idle:
        return AppColors.cardBorder;
    }
  }

  Color _letterColor() {
    switch (state) {
      case QuizOptionTileState.correct:
        return AppColors.success;
      case QuizOptionTileState.wrong:
        return AppColors.danger;
      case QuizOptionTileState.selected:
        return AppColors.gold;
      case QuizOptionTileState.idle:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _backgroundColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: _borderColor(), width: 1.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28.r,
                height: 28.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _letterColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: _borderColor()),
                ),
                child: Text(
                  quizOptionLetter(index),
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: _letterColor(),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: state == QuizOptionTileState.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              ?trailing,
              if (trailing == null && state == QuizOptionTileState.correct)
                Icon(Icons.check_circle, color: AppColors.success, size: 20.r),
              if (trailing == null && state == QuizOptionTileState.wrong)
                Icon(Icons.cancel, color: AppColors.danger, size: 20.r),
            ],
          ),
        ),
      ),
    );
  }
}
