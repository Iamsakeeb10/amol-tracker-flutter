import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';
import 'text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData? _cachedTheme;
  static String? _cachedLocaleTag;

  static ThemeData build(BuildContext context, {Locale? locale}) {
    final localeTag = locale?.toLanguageTag() ?? 'default';
    if (_cachedTheme != null && _cachedLocaleTag == localeTag) {
      return _cachedTheme!;
    }

    final base = ThemeData.dark(useMaterial3: true);
    final isBn = locale?.languageCode == 'bn';
    final baseTextTheme = isBn
        ? GoogleFonts.notoSansBengaliTextTheme(base.textTheme)
        : GoogleFonts.dmSansTextTheme(base.textTheme);

    _cachedLocaleTag = localeTag;
    _cachedTheme = base.copyWith(
      scaffoldBackgroundColor: AppColors.emeraldDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        onPrimary: AppColors.emeraldDeep,
        secondary: AppColors.goldLight,
        onSecondary: AppColors.emeraldDeep,
        surface: AppColors.emeraldMid,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: AppColors.textPrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: AppTextStyles.displayLarge(context, locale: locale),
        displayMedium: AppTextStyles.displayMedium(context, locale: locale),
        headlineLarge: AppTextStyles.headlineLarge(context, locale: locale),
        headlineMedium: AppTextStyles.headlineMedium(context, locale: locale),
        bodyLarge: AppTextStyles.bodyLarge(context, locale: locale),
        bodyMedium: AppTextStyles.bodyMedium(context, locale: locale),
        bodySmall: AppTextStyles.bodySmall(context, locale: locale),
        labelMedium: AppTextStyles.label(context, locale: locale),
        labelLarge: AppTextStyles.button(context, locale: locale),
      ),
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.headlineMedium(context, locale: locale),
        systemOverlayStyle: null,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.emeraldMid.withValues(alpha: 0.65),
        indicatorColor: AppColors.goldCard,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.gold);
          }
          return const IconThemeData(color: AppColors.textMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTextStyles.navLabel(
            context,
            locale: locale,
            selected: selected,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.gold;
          }
          return AppColors.cardBorder;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.emeraldDeep;
          }
          return AppColors.textSecondary;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.emeraldMid,
        hourMinuteColor: AppColors.cardBorder,
        hourMinuteTextColor: AppColors.textPrimary,
        dayPeriodColor: AppColors.cardBorder,
        dayPeriodTextColor: AppColors.textPrimary,
        dialBackgroundColor: AppColors.emeraldLight,
        dialHandColor: AppColors.gold,
        dialTextColor: AppColors.textPrimary,
        entryModeIconColor: AppColors.gold,
        helpTextStyle: AppTextStyles.label(
          context,
          locale: locale,
        ).copyWith(color: AppColors.gold),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.gold),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1.r,
        space: 0,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary, size: 20.r),
    );
    return _cachedTheme!;
  }
}
