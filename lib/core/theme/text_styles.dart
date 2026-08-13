import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static String _localeCode(BuildContext context, {Locale? locale}) {
    return locale?.languageCode ?? Localizations.localeOf(context).languageCode;
  }

  static bool _isBn(BuildContext context, {Locale? locale}) {
    return _localeCode(context, locale: locale) == 'bn';
  }

  static TextStyle _displayFont(
    BuildContext context, {
    Locale? locale,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textPrimary,
    double? height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFamily: _isBn(context, locale: locale)
          ? 'NotoSansBengali'
          : 'PlusJakartaSans',
      decoration: TextDecoration.none,
    );
  }

  static TextStyle _bodyFont(
    BuildContext context, {
    Locale? locale,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
    double letterSpacing = 0,
  }) {
    return _displayFont(
      context,
      locale: locale,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle displayLarge(BuildContext context, {Locale? locale}) =>
      _displayFont(context, locale: locale, fontSize: 36.sp, height: 1.1);

  static TextStyle displayMedium(BuildContext context, {Locale? locale}) =>
      _displayFont(context, locale: locale, fontSize: 28.sp, height: 1.40);

  static TextStyle headlineLarge(BuildContext context, {Locale? locale}) =>
      _displayFont(
        context,
        locale: locale,
        fontSize: 22.sp,
        letterSpacing: 0.2,
      );

  static TextStyle headlineMedium(BuildContext context, {Locale? locale}) =>
      _displayFont(
        context,
        locale: locale,
        fontSize: 18.sp,
        fontWeight: FontWeight.w500,
      );

  static TextStyle goldNumeric(BuildContext context, {Locale? locale}) =>
      _displayFont(
        context,
        locale: locale,
        fontSize: 26.sp,
        color: AppColors.goldLight,
      );

  static TextStyle bodyLarge(BuildContext context, {Locale? locale}) =>
      _bodyFont(context, locale: locale, fontSize: 15.sp, height: 1.5);

  static TextStyle bodyMedium(BuildContext context, {Locale? locale}) =>
      _bodyFont(
        context,
        locale: locale,
        fontSize: 13.5.sp,
        color: AppColors.textSecondary,
        height: 1.45,
      );

  static TextStyle bodySmall(BuildContext context, {Locale? locale}) =>
      _bodyFont(
        context,
        locale: locale,
        fontSize: 12.sp,
        color: AppColors.textMuted,
        height: 1.4,
      );

  static TextStyle label(BuildContext context, {Locale? locale}) => _bodyFont(
    context,
    locale: locale,
    fontSize: 11.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: _isBn(context, locale: locale) ? 0 : 1.4,
  );

  static TextStyle button(BuildContext context, {Locale? locale}) => _bodyFont(
    context,
    locale: locale,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  static TextStyle pill(BuildContext context, {Locale? locale}) => _bodyFont(
    context,
    locale: locale,
    fontSize: 11.sp,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  static TextStyle navLabel(
    BuildContext context, {
    Locale? locale,
    required bool selected,
  }) {
    return _bodyFont(
      context,
      locale: locale,
      fontSize: 11.sp,
      fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
      color: selected ? AppColors.gold : AppColors.textMuted,
      letterSpacing: 0.4,
    );
  }

  // Aliases for Material 3 naming
  static TextStyle titleLarge(BuildContext context, {Locale? locale}) => headlineMedium(context, locale: locale);
  static TextStyle titleMedium(BuildContext context, {Locale? locale}) => bodyLarge(context, locale: locale);
  static TextStyle titleSmall(BuildContext context, {Locale? locale}) => bodyMedium(context, locale: locale).copyWith(fontWeight: FontWeight.bold);
  
  static TextStyle labelLarge(BuildContext context, {Locale? locale}) => label(context, locale: locale);
  static TextStyle labelMedium(BuildContext context, {Locale? locale}) => label(context, locale: locale).copyWith(fontSize: 12);
  static TextStyle labelSmall(BuildContext context, {Locale? locale}) => bodySmall(context, locale: locale);
}
