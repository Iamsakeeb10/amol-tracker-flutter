import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import 'quran_constants.dart';

/// Arabic mushaf text styles using the bundled [DigitalKhattIndopak] font.
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
  }) {
    return TextStyle(
      fontFamily: QuranConstants.arabicFontFamily,
      fontSize: fontSize,
      height: height,
      color: color,
      fontWeight: fontWeight,
      backgroundColor: backgroundColor,
      decoration: TextDecoration.none,
    );
  }
}
