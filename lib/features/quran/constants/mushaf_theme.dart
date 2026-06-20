import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// Named mushaf paper theme with background and ink colors.
class MushafPaperTheme {
  const MushafPaperTheme({
    required this.paper,
    required this.ink,
    required this.surahTitle,
    required this.ayahMarker,
    required this.pageNumber,
    required this.paperBorder,
  });

  final Color paper;
  final Color ink;
  final Color surahTitle;
  final Color ayahMarker;
  final Color pageNumber;
  final Color paperBorder;
}

/// Visual and layout tokens for the line-based mushaf reader.
abstract final class MushafTheme {
  // Paper & ink (app emerald default)
  static const paper = AppColors.emeraldMid;
  static const paperBorder = AppColors.emeraldLight;
  static const ink = AppColors.textPrimary;
  static const surahTitle = AppColors.gold;
  static const ayahMarker = AppColors.gold;
  static const pageNumber = AppColors.textSecondary;

  /// User-selectable paper themes (background + ink pairs).
  static const paperThemes = <MushafPaperTheme>[
    MushafPaperTheme(
      paper: AppColors.emeraldMid,
      ink: AppColors.textPrimary,
      surahTitle: AppColors.gold,
      ayahMarker: AppColors.gold,
      pageNumber: AppColors.textSecondary,
      paperBorder: AppColors.emeraldLight,
    ),
    MushafPaperTheme(
      paper: Color(0xFFFFFFFF),
      ink: Color(0xFF1A1A1A),
      surahTitle: Color(0xFF2D4A3E),
      ayahMarker: Color(0xFF2D4A3E),
      pageNumber: Color(0xFF6B5E4E),
      paperBorder: Color(0xFFD4C4A8),
    ),
    MushafPaperTheme(
      paper: Color(0xFFF5EBDC),
      ink: Color(0xFF1A1A1A),
      surahTitle: Color(0xFF2D4A3E),
      ayahMarker: Color(0xFF2D4A3E),
      pageNumber: Color(0xFF6B5E4E),
      paperBorder: Color(0xFFD4C4A8),
    ),
    MushafPaperTheme(
      paper: Color(0xFFF0F4EB),
      ink: Color(0xFF1A1A1A),
      surahTitle: Color(0xFF2D4A3E),
      ayahMarker: Color(0xFF2D4A3E),
      pageNumber: Color(0xFF6B5E4E),
      paperBorder: Color(0xFFC8D4BC),
    ),
    MushafPaperTheme(
      paper: Color(0xFF2B2620),
      ink: Color(0xFFEAE0D0),
      surahTitle: Color(0xFFC8B89A),
      ayahMarker: Color(0xFFC8B89A),
      pageNumber: Color(0xFF9A8E7E),
      paperBorder: Color(0xFF4A4238),
    ),
    MushafPaperTheme(
      paper: Color(0xFF1A1A2E),
      ink: Color(0xFFE8E8F0),
      surahTitle: Color(0xFFB8B8D0),
      ayahMarker: Color(0xFFB8B8D0),
      pageNumber: Color(0xFF8888A0),
      paperBorder: Color(0xFF2E2E48),
    ),
  ];

  static MushafPaperTheme themeAt(int index) {
    return paperThemes[index.clamp(0, paperThemes.length - 1)];
  }

  // Layout
  static const pageBorderRadius = 6.0;
  static const pageOuterPaddingH = 8.0;
  static const pageOuterPaddingV = 6.0;
  static const pageInnerPaddingH = 6.0;
  static const pageInnerPaddingTop = 4.0;
  static const pageFooterHeight = 26.0;
  static const pageShadowOpacity = 0.18;

  // Surah banner
  static const surahBannerPaddingH = 12.0;
  static const surahBannerPaddingV = 2.0;
  static const surahBannerBorderWidth = 1.5;

  // Typography scaling
  static const ayahLineFontRatio = 0.66;
  static const surahNameFontRatio = 0.72;
  static const pageNumberFontSize = 13.0;
  static const minFontSize = 10.0;
  static const maxFontSize = 64.0;

  /// Minimum user scale (80%) and maximum (160%).
  static const minUserScale = 0.8;
  static const maxUserScale = 1.6;

  static double scaleProgress(double fontScale) {
    return ((fontScale - 1.0) / (maxUserScale - 1.0)).clamp(0.0, 1.0);
  }

  /// Shrinks horizontal margins as font scale rises above 100% to free line width.
  static double outerPaddingHForScale(double fontScale) {
    if (fontScale <= 1.0) return pageOuterPaddingH;
    final t = scaleProgress(fontScale);
    return pageOuterPaddingH * (1.0 - t);
  }

  static double innerPaddingHForScale(double fontScale) {
    if (fontScale <= 1.0) return pageInnerPaddingH;
    final t = scaleProgress(fontScale);
    return pageInnerPaddingH * (1.0 - t);
  }

  static double innerPaddingTopForScale(double fontScale) {
    if (fontScale <= 1.0) return pageInnerPaddingTop;
    final t = scaleProgress(fontScale);
    return pageInnerPaddingTop * (1.0 - t * 0.5);
  }

  /// Shrinks the page footer at high zoom to give lines more height.
  static double pageFooterHeightForScale(double fontScale) {
    if (fontScale <= 1.0) return pageFooterHeight;
    final t = scaleProgress(fontScale);
    return pageFooterHeight * (1.0 - t * 0.55);
  }

  static double surahBannerPaddingHForScale(double fontScale) {
    if (fontScale <= 1.0) return surahBannerPaddingH;
    final t = scaleProgress(fontScale);
    return surahBannerPaddingH * (1.0 - t * 0.75);
  }

  /// Uses more of each line slot vertically as zoom increases.
  static double heightFillForScale(double fontScale) {
    if (fontScale <= 1.0) return 0.92;
    final t = scaleProgress(fontScale);
    return 0.92 + t * 0.07;
  }

  /// Uses more horizontal space as zoom increases (up to full width).
  static double widthSafetyForScale(double fontScale) {
    if (fontScale <= 1.0) return 0.985;
    final t = scaleProgress(fontScale);
    return 0.985 + t * 0.015;
  }

  static BoxDecoration pageDecoration({
    required double borderRadius,
    Color? paperColor,
    Color? borderColor,
    bool fullBleed = false,
  }) {
    if (fullBleed) {
      return BoxDecoration(color: paperColor ?? paper);
    }

    return BoxDecoration(
      color: paperColor ?? paper,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? paperBorder, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: pageShadowOpacity),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration surahBannerDecoration({Color? borderColor}) {
    final color = borderColor ?? surahTitle;
    return BoxDecoration(
      border: Border(
        top: BorderSide(color: color, width: surahBannerBorderWidth),
        bottom: BorderSide(color: color, width: surahBannerBorderWidth),
      ),
    );
  }
}
