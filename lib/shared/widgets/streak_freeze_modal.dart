import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import 'card_container.dart';

class StreakFreezeModal extends StatelessWidget {
  final int preservedStreak;
  final int freezesLeft;
  final int totalFreezes;
  final VoidCallback? onUseFreeze;
  final VoidCallback? onResetStreak;

  const StreakFreezeModal({
    super.key,
    this.preservedStreak = 1,
    this.freezesLeft = 1,
    this.totalFreezes = 1,
    this.onUseFreeze,
    this.onResetStreak,
  });

  /// S-16 — one freeze per week when user missed exactly one Hijri day.
  static Future<void> show(
    BuildContext context, {
    required int preservedStreak,
    VoidCallback? onUseFreeze,
    VoidCallback? onResetStreak,
    int freezesLeft = 1,
    int totalFreezes = 1,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StreakFreezeModal(
        preservedStreak: preservedStreak,
        freezesLeft: freezesLeft,
        totalFreezes: totalFreezes,
        onUseFreeze: onUseFreeze,
        onResetStreak: onResetStreak,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: SafeArea(
        top: false,
        child: CardContainer(
          color: AppColors.emeraldMid,
          borderColor: AppColors.goldBorder,
          radius: 24,
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 64.r,
                  height: 64.r,
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.ac_unit,
                    color: AppColors.warning,
                    size: 28.r,
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Center(
                child: Text(
                  'Streak Freeze',
                  style: AppTextStyles.headlineLarge(context),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "You missed yesterday. Use a streak freeze to keep your $preservedStreak-day streak alive — your habit, intact.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(context),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldCard,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.goldBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.gold,
                      size: 18.r,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Freezes left this week',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '$freezesLeft / $totalFreezes',
                      style: AppTextStyles.goldNumeric(context).copyWith(fontSize: 18.sp),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed: () {
                    onUseFreeze?.call();
                    Navigator.of(context).maybePop();
                  },
                  child: Text(
                    'Yes, use my freeze',
                    style: AppTextStyles.button(context).copyWith(
                      color: AppColors.emeraldDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                height: 44.h,
                child: TextButton(
                  onPressed: () {
                    onResetStreak?.call();
                    Navigator.of(context).maybePop();
                  },
                  child: Text(
                    'No, reset my streak',
                    style: AppTextStyles.button(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
