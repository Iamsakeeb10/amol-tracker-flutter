import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';
import 'personal_amol_details_dialog.dart';

/// Short "how My Amol works" dialog opened from the home section info button.
Future<void> showPersonalAmolInfoDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    barrierColor: PersonalAmolDialogColors.barrier,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        child: CardContainer(
          color: PersonalAmolDialogColors.dialogBg,
          borderColor: PersonalAmolDialogColors.dialogBorder,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.personalAmolInfoTitle,
                style: AppTextStyles.headlineMedium(context).copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 14.h),
              _InfoBullet(text: l10n.personalAmolInfoBody1),
              SizedBox(height: 10.h),
              _InfoBullet(text: l10n.personalAmolInfoBody2),
              SizedBox(height: 10.h),
              _InfoBullet(text: l10n.personalAmolInfoBody3),
              SizedBox(height: 10.h),
              _InfoBullet(text: l10n.personalAmolInfoBody4),
              SizedBox(height: 10.h),
              _InfoBullet(text: l10n.personalAmolInfoBody5),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    l10n.personalAmolInfoGotIt,
                    style: AppTextStyles.button(context).copyWith(
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
    },
  );
}

class _InfoBullet extends StatelessWidget {
  const _InfoBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Container(
            width: 6.r,
            height: 6.r,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
