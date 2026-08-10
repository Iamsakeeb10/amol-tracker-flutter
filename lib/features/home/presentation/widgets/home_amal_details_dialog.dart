import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/card_container.dart';
import 'home_widgets.dart';

abstract final class HomeUiDialogColors {
  static final barrier = Colors.black.withValues(alpha: 0.6);
  static final dialogBorder = AppColors.goldBorder.withValues(alpha: 0.8);
  static final dialogBg = AppColors.emeraldMid.withValues(alpha: 0.98);
  static final shadow = Colors.black.withValues(alpha: 0.35);
  static final sublabelBg = AppColors.emeraldDeep.withValues(alpha: 0.88);
  static final sublabelBorder = AppColors.goldBorder.withValues(alpha: 0.45);
}

Future<void> showHomeAmalDetailsDialog(
  BuildContext context,
  AmalField field,
  String locale,
) async {
  final l10n = AppLocalizations.of(context)!;
  await showDialog<void>(
    context: context,
    barrierColor: HomeUiDialogColors.barrier,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        child: CardContainer(
          padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 14.h),
          borderColor: HomeUiDialogColors.dialogBorder,
          color: HomeUiDialogColors.dialogBg,
          boxShadow: [
            BoxShadow(
              color: HomeUiDialogColors.shadow,
              blurRadius: 24.r,
              offset: Offset(0, 10.h),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42.r,
                    height: 42.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.goldCard,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.goldBorder),
                    ),
                    child: AmalFieldIcon(
                      fieldId: field.id,
                      color: AppColors.gold,
                      size: 22.r,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.getLabel(locale),
                          style: AppTextStyles.bodyLarge(context).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          field.getLabel(locale == 'bn' ? 'en' : 'bn'),
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 20.r,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: HomeUiDialogColors.sublabelBg,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: HomeUiDialogColors.sublabelBorder),
                ),
                child: Text(
                  field.getSublabel(locale),
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(color: AppColors.textPrimary, height: 1.35),
                ),
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  HomeDetailChip(
                    icon: Icons.workspace_premium_outlined,
                    text: '+${field.points} pts',
                  ),
                  HomeDetailChip(
                    icon: field.type == AmalType.numeric
                        ? Icons.pin_outlined
                        : Icons.toggle_on_outlined,
                    text: field.type == AmalType.numeric
                        ? 'Target: ${field.maxValue}'
                        : 'Type: Toggle',
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        side: const BorderSide(color: AppColors.goldBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          l10n.cancel,
                          style: AppTextStyles.button(context).copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (field.id == 'morning_azkar' ||
                      field.id == 'evening_azkar' ||
                      field.id == 'quran' ||
                      field.id == 'mulk') ...[
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          if (field.id == 'morning_azkar' || field.id == 'evening_azkar') {
                            context.push(
                              AppRoutes.dua,
                              extra: 'morning-and-evening',
                            );
                          } else if (field.id == 'quran') {
                            context.push(AppRoutes.quran);
                          } else if (field.id == 'mulk') {
                            context.push(AppRoutes.quranSurahScrollPath(67));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.emeraldDeep,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 11.h),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n.readAction,
                            style: AppTextStyles.button(context).copyWith(
                              color: AppColors.emeraldDeep,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
