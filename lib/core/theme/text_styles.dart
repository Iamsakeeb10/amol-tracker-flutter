import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static final Map<String, TextStyle> _cache = {};

  static TextStyle _cached(String key, TextStyle Function() build) {
    return _cache.putIfAbsent(key, build);
  }

  static TextStyle displayLarge(BuildContext context) => _cached(
    'displayLarge',
    () => GoogleFonts.cormorantGaramond(
      fontSize: 36.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.1,
      decoration: TextDecoration.none,
    ),
  );

  static TextStyle displayMedium(BuildContext context) => _cached(
    'displayMedium',
    () => GoogleFonts.cormorantGaramond(
      fontSize: 28.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.15,
      decoration: TextDecoration.none,
    ),
  );

  static TextStyle headlineLarge(BuildContext context) => _cached(
    'headlineLarge',
    () => GoogleFonts.cormorantGaramond(
      fontSize: 22.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.2,
      decoration: TextDecoration.none,
    ),
  );

  static TextStyle headlineMedium(BuildContext context) => _cached(
    'headlineMedium',
    () => GoogleFonts.cormorantGaramond(
      fontSize: 18.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
      decoration: TextDecoration.none,
    ),
  );

  static TextStyle goldNumeric(BuildContext context) => _cached(
    'goldNumeric',
    () => GoogleFonts.cormorantGaramond(
      fontSize: 26.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.goldLight,
      decoration: TextDecoration.none,
    ),
  );

  static TextStyle bodyLarge(BuildContext context) => _cached(
    'bodyLarge',
    () => GoogleFonts.dmSans(
      fontSize: 15.sp,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      height: 1.5,
      decoration: TextDecoration.none,
    ),
  );

  static TextStyle bodyMedium(BuildContext context) => _cached(
    'bodyMedium',
    () => GoogleFonts.dmSans(
      fontSize: 13.5.sp,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.45,
      decoration: TextDecoration.none,
    ),
  );

  static TextStyle bodySmall(BuildContext context) => _cached(
    'bodySmall',
    () => GoogleFonts.dmSans(
      fontSize: 12.sp,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
      height: 1.4,
      decoration: TextDecoration.none,
    ),
  );

  static TextStyle label(BuildContext context) => _cached(
    'label',
    () => GoogleFonts.dmSans(
      fontSize: 11.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
      letterSpacing: 1.4,
      decoration: TextDecoration.none,
    ),
  );

  static TextStyle button(BuildContext context) => _cached(
    'button',
    () => GoogleFonts.dmSans(
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
      letterSpacing: 0.4,
      decoration: TextDecoration.none,
    ),
  );

  static TextStyle pill(BuildContext context) => _cached(
    'pill',
    () => GoogleFonts.dmSans(
      fontSize: 11.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
      letterSpacing: 0.4,
      decoration: TextDecoration.none,
    ),
  );
}
