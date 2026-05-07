import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';
import 'text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
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
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: AppTextStyles.displayLarge(context),
        displayMedium: AppTextStyles.displayMedium(context),
        headlineLarge: AppTextStyles.headlineLarge(context),
        headlineMedium: AppTextStyles.headlineMedium(context),
        bodyLarge: AppTextStyles.bodyLarge(context),
        bodyMedium: AppTextStyles.bodyMedium(context),
        bodySmall: AppTextStyles.bodySmall(context),
        labelMedium: AppTextStyles.label(context),
        labelLarge: AppTextStyles.button(context),
      ),
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.headlineMedium(context),
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
          return GoogleFonts.dmSans(
            fontSize: 11.sp,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            color: selected ? AppColors.gold : AppColors.textMuted,
            letterSpacing: 0.4,
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
      dividerTheme: DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1.r,
        space: 0,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary, size: 20.r),
    );
  }
}
