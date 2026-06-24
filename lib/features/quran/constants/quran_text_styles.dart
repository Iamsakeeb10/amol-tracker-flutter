import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import 'quran_constants.dart';

/// Arabic text styles using the bundled [ScheherazadeNew] font for Uthmani script.
///
/// Do not build these from [AppTextStyles] — Google Fonts sets `package:
/// google_fonts` on those styles, which prevents app-bundled fonts from loading
/// even when `fontFamily` is overridden via `copyWith`.
class QuranTextStyles {
  QuranTextStyles._();

  /// Ayah list / surah scroll Arabic — raw Tanzil text, no code-point rewriting.
  static TextStyle arabic({
    required double fontSize,
    Color color = AppColors.textPrimary,
    double height = QuranConstants.arabicLineHeight,
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
      leadingDistribution: TextLeadingDistribution.proportional,
    );
  }

  /// Mushaf page text — uses [ScheherazadeNew] for Uthmani script and diacritics.
  ///
  /// [height] defaults to `null` so Flutter uses the font's own ascent/descent
  /// metrics. Forcing a tight [TextStyle.height] clips Arabic diacritics.
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

  /// Line metrics tuned for Scheherazade New mushaf rendering.
  static const textHeightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
    leadingDistribution: TextLeadingDistribution.proportional,
  );
}
