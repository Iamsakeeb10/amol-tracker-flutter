import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/bengali_numeral_helper.dart';
import '../../../../l10n/app_localizations.dart';

/// Compact `− c/target +` counter for count-type personal amols on the home
/// tile. Rendered read-only when no callbacks are provided.
///
/// When the count is already at the target (max) or at 0 (min), tapping the
/// +/− button swallows the tap (so it never falls through to the tile's tap
/// target) and shows a localized snackbar with a close action instead.
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
    final l10n = AppLocalizations.of(context)!;
    final isDone = doneCount >= target;
    final canDecrement = onDecrement != null && doneCount > 0;
    final canIncrement = onIncrement != null && !isDone;

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
            onTapAtLimit: canDecrement
                ? null
                : () => _showLimitSnack(context, l10n.personalAmolCountMinReached),
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
            onTapAtLimit: canIncrement
                ? null
                : () => _showLimitSnack(context, l10n.personalAmolCountMaxReached),
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
    required VoidCallback? onTapAtLimit,
    required bool onFilled,
  }) {
    final active = enabled ? onTap : onTapAtLimit;
    return GestureDetector(
      // Claim the tap even when disabled so it never falls through to the
      // card's onTap (details dialog); show the limit snackbar instead.
      onTap: active,
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

  void _showLimitSnack(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.warning,
          duration: const Duration(milliseconds: 3000),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.closeLabel,
            textColor: AppColors.emeraldDeep,
            onPressed: messenger.hideCurrentSnackBar,
          ),
        ),
      );
  }
}