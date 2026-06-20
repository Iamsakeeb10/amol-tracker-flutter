import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import 'quran_constants.dart';

/// Arabic mushaf text styles using the bundled [IndopakNastaleeq] font.
///
/// Do not build these from [AppTextStyles] — Google Fonts sets `package:
/// google_fonts` on those styles, which prevents app-bundled fonts from loading
/// even when `fontFamily` is overridden via `copyWith`.
class QuranTextStyles {
  QuranTextStyles._();

  static TextStyle arabic({
    required double fontSize,
    Color color = AppColors.textPrimary,
    double height = 2.0,
    FontWeight fontWeight = FontWeight.w400,
    Color? backgroundColor,
    String? fontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? QuranConstants.arabicFontFamily,
      fontSize: fontSize,
      height: height,
      color: color,
      fontWeight: fontWeight,
      backgroundColor: backgroundColor,
      decoration: TextDecoration.none,
    );
  }

  /// Mushaf page text — uses [QpcNastaleeq] for ornate ayah-end marker glyphs.
  ///
  /// [height] defaults to `null` so Flutter uses the font's own ascent/descent
  /// metrics. Forcing a tight [TextStyle.height] clips Nastaleeq diacritics.
  static TextStyle mushaf({
    required double fontSize,
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
  }) {
    return TextStyle(
      fontFamily: QuranConstants.mushafFontFamily,
      fontSize: fontSize,
      height: height,
      color: color,
      fontWeight: fontWeight,
      decoration: TextDecoration.none,
      leadingDistribution: TextLeadingDistribution.proportional,
    );
  }

  /// Line metrics tuned for QPC / Indo-Pak Nastaleeq mushaf fonts.
  static const textHeightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
    leadingDistribution: TextLeadingDistribution.proportional,
  );
}
