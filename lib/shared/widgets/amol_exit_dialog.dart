import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/exit_app_debug.dart';
import '../../l10n/app_localizations.dart';

class AmolExitDialog extends StatelessWidget {
  const AmolExitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    exitAppDebug('AmolExitDialog — build');
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: AppColors.emeraldDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: AppColors.goldBorder, width: 1.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.goldCard,
                border: Border.all(color: AppColors.goldBorder, width: 1.r),
              ),
              child: Icon(
                Icons.exit_to_app_rounded,
                color: AppColors.goldLight,
                size: 26.r,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.exitAppTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium(context).copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.exitAppConfirm,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(context).copyWith(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      exitAppDebug('AmolExitDialog — Stay tapped');
                      Navigator.pop(context, false);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      side: BorderSide(color: AppColors.goldBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      l10n.exitAppStay,
                      style: AppTextStyles.button(context).copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      exitAppDebug('AmolExitDialog — Exit tapped');
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.emeraldDeep,
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.exitApp,
                      style: AppTextStyles.button(context).copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emeraldDeep,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
