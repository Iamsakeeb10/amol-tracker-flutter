import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class CourseCertificateCard extends StatelessWidget {
  const CourseCertificateCard({
    super.key,
    required this.courseTitle,
    required this.userName,
    required this.completedAt,
  });

  final String courseTitle;
  final String userName;
  final DateTime completedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateLabel = DateFormat.yMMMMd().format(completedAt);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emeraldDeep, Color(0xFF0A3D2E)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium, color: AppColors.gold, size: 40.r),
          SizedBox(height: 12.h),
          Text(
            l10n.courseCertificateTitle,
            style: AppTextStyles.headlineMedium(context).copyWith(
              color: AppColors.gold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.courseCertificateArabic,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.goldLight,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            l10n.courseCertificatePresentedTo,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            userName.trim().isEmpty ? l10n.displayName : userName,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium(context).copyWith(
              color: AppColors.cream,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.courseCertificateForCourse,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            courseTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge(context).copyWith(
              color: AppColors.goldLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            l10n.courseCertificateDate(dateLabel),
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
