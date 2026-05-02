import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLarge(BuildContext context) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 36.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  static TextStyle displayMedium(BuildContext context) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 28.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.15,
      );

  static TextStyle headlineLarge(BuildContext context) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle headlineMedium(BuildContext context) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 18.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle goldNumeric(BuildContext context) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 26.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.goldLight,
      );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.dmSans(
        fontSize: 15.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.dmSans(
        fontSize: 13.5.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.45,
      );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.dmSans(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.4,
      );

  static TextStyle label(BuildContext context) => GoogleFonts.dmSans(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 1.4,
      );

  static TextStyle button(BuildContext context) => GoogleFonts.dmSans(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.4,
      );

  static TextStyle pill(BuildContext context) => GoogleFonts.dmSans(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.4,
      );
}
