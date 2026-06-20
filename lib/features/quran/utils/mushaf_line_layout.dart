import 'package:flutter/material.dart';

import '../constants/mushaf_theme.dart';
import '../constants/quran_text_styles.dart';
import '../models/mushaf_layout_info.dart';

/// Builds mushaf [TextSpan]s and computes font sizes for user scaling.
abstract final class MushafLineLayout {
  /// Resolved font size plus optional vertical-only boost when width is saturated.
  static MushafLineMetrics resolveLineMetrics({
    required MushafRenderedLine line,
    required double maxWidth,
    required double maxHeight,
    required double userScale,
    TextScaler textScaler = TextScaler.noScaling,
    bool includeBanner = false,
  }) {
    if (maxWidth <= 0 || maxHeight <= 0 || userScale <= 0) {
      return const MushafLineMetrics(
        fontSize: MushafTheme.minFontSize,
        verticalScale: 1,
      );
    }

    final widthSafety = MushafTheme.widthSafetyForScale(userScale);
    final heightFill = MushafTheme.heightFillForScale(userScale);
    final bannerPadH = includeBanner
        ? MushafTheme.surahBannerPaddingHForScale(userScale)
        : 0.0;
    final baseRatio = line.isSurahName
        ? MushafTheme.surahNameFontRatio
        : MushafTheme.ayahLineFontRatio;

    final baseFontSize = _fitFontSize(
      line: line,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      textScaler: textScaler,
      includeBanner: includeBanner,
      bannerPaddingH: MushafTheme.surahBannerPaddingH,
      widthSafetyRatio: MushafTheme.widthSafetyForScale(1),
      heightFillRatio: MushafTheme.heightFillForScale(1),
      highRatio: baseRatio,
    );

    final targetFontSize = _fitFontSize(
      line: line,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      textScaler: textScaler,
      includeBanner: includeBanner,
      bannerPaddingH: bannerPadH,
      widthSafetyRatio: widthSafety,
      heightFillRatio: heightFill,
      highRatio: baseRatio * userScale,
    );

    final visualTarget = baseFontSize * userScale;
    var verticalScale = 1.0;
    if (userScale > 1.0 && targetFontSize + 0.15 < visualTarget) {
      verticalScale = (visualTarget / targetFontSize).clamp(1.0, 1.45);
    }

    return MushafLineMetrics(
      fontSize: targetFontSize,
      verticalScale: verticalScale,
    );
  }

  static double _fitFontSize({
    required MushafRenderedLine line,
    required double maxWidth,
    required double maxHeight,
    required TextScaler textScaler,
    required bool includeBanner,
    required double bannerPaddingH,
    required double widthSafetyRatio,
    required double heightFillRatio,
    required double highRatio,
  }) {
    final safeWidth = maxWidth * widthSafetyRatio;
    final targetHeight = maxHeight * heightFillRatio;

    var high = (maxHeight * highRatio)
        .clamp(MushafTheme.minFontSize, MushafTheme.maxFontSize);
    var low = MushafTheme.minFontSize;
    var best = low;

    while (high - low > 0.05) {
      final mid = (high + low) / 2;
      final size = measureIntrinsic(
        line: line,
        fontSize: mid,
        textScaler: textScaler,
        includeBanner: includeBanner,
        bannerPaddingH: bannerPaddingH,
      );
      if (size.width <= safeWidth && size.height <= targetHeight) {
        best = mid;
        low = mid;
      } else {
        high = mid;
      }
    }

    return best.clamp(MushafTheme.minFontSize, MushafTheme.maxFontSize);
  }

  static Size measureIntrinsic({
    required MushafRenderedLine line,
    required double fontSize,
    TextScaler textScaler = TextScaler.noScaling,
    bool includeBanner = false,
    double bannerPaddingH = MushafTheme.surahBannerPaddingH,
  }) {
    final painter = TextPainter(
      text: buildTextSpan(line: line, fontSize: fontSize),
      textDirection: TextDirection.rtl,
      textScaler: textScaler,
      textHeightBehavior: QuranTextStyles.textHeightBehavior,
      maxLines: 1,
    )..layout();

    var width = painter.size.width;
    var height = painter.size.height;

    if (includeBanner) {
      width += bannerPaddingH * 2;
      height += MushafTheme.surahBannerPaddingV * 2;
      height += MushafTheme.surahBannerBorderWidth * 2;
    }

    return Size(width, height);
  }

  static TextSpan buildTextSpan({
    required MushafRenderedLine line,
    required double fontSize,
    Color textColor = MushafTheme.ink,
    Color ayahMarkerColor = MushafTheme.ayahMarker,
    Color? surahTitleColor,
  }) {
    if (line.isSurahName) {
      return TextSpan(
        text: line.text,
        style: QuranTextStyles.mushaf(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: surahTitleColor ?? ayahMarkerColor,
        ),
      );
    }

    final segments = line.segments;
    if (segments.isEmpty) {
      return TextSpan(
        text: line.text,
        style: QuranTextStyles.mushaf(
          fontSize: fontSize,
          color: textColor,
        ),
      );
    }

    return TextSpan(
      style: QuranTextStyles.mushaf(
        fontSize: fontSize,
        color: textColor,
      ),
      children: [
        for (final segment in segments)
          TextSpan(
            text: '${segment.leadingSpace ? ' ' : ''}${segment.text}',
            style: segment.isAyahEnd
                ? QuranTextStyles.mushaf(
                    fontSize: fontSize,
                    color: ayahMarkerColor,
                  )
                : null,
          ),
      ],
    );
  }
}

/// Font size and optional vertical stretch when a line is width-saturated.
class MushafLineMetrics {
  const MushafLineMetrics({
    required this.fontSize,
    required this.verticalScale,
  });

  final double fontSize;
  final double verticalScale;
}
