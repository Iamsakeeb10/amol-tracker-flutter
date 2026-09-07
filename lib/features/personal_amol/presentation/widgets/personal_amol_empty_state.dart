import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class PersonalAmolEmptyState extends StatelessWidget {
  const PersonalAmolEmptyState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.goldCard,
            AppColors.cardDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: AppColors.goldBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.gold.withValues(alpha: 0.25),
                  AppColors.gold.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(Icons.auto_awesome, color: AppColors.gold, size: 20.r),
          ),
          SizedBox(height: AppSpacing.md.h),
          Text(
            l10n.personalAmolEmptyHeadline,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.xs.h),
          Text(
            l10n.personalAmolEmptySubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.label(context).copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: AppSpacing.lg.h),
          Center(
            child: SizedBox(
              height: 40.h,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: Icon(Icons.add_rounded, size: 16.r),
                label: Text(
                  l10n.personalAmolEmptyCta,
                  style: AppTextStyles.button(context).copyWith(
                    color: AppColors.emeraldDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}