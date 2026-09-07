import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/bengali_numeral_helper.dart';

/// Compact `− c/target +` counter for count-type personal amols on the home
/// tile. Rendered read-only when no callbacks are provided.
class PersonalAmolStepper extends StatelessWidget {
  const PersonalAmolStepper({
    super.key,
    required this.doneCount,
    required this.target,
    this.onIncrement,
    this.onDecrement,
  });

  final int doneCount;
  final int target;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final isDone = doneCount >= target;
    final canDecrement = onDecrement != null && doneCount > 0;
    final canIncrement = onIncrement != null;

    return Container(
      height: 38.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: isDone ? AppColors.gold : AppColors.cardDark,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDone ? AppColors.gold : AppColors.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(
            context,
            icon: Icons.remove,
            enabled: canDecrement,
            onTap: onDecrement,
            onFilled: isDone,
          ),
          SizedBox(
            width: 44.w,
            child: Center(
              child: Text(
                '${toBengaliNumeral(doneCount)}/'
                '${toBengaliNumeral(target)}',
                style: AppTextStyles.label(context).copyWith(
                  fontSize: 10.sp,
                  color: isDone
                      ? AppColors.emeraldDeep
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _button(
            context,
            icon: Icons.add,
            enabled: canIncrement,
            onTap: onIncrement,
            onFilled: isDone,
          ),
        ],
      ),
    );
  }

  Widget _button(
    BuildContext context, {
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
    required bool onFilled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28.w,
        height: 28.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onFilled
              ? AppColors.emeraldDeep.withValues(alpha: 0.14)
              : AppColors.cardBorder,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 15.r,
          color: enabled
              ? (onFilled ? AppColors.emeraldDeep : AppColors.gold)
              : AppColors.textMuted,
        ),
      ),
    );
  }
}