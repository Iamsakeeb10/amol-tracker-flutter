import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/mushaf_theme.dart';
import '../../../constants/quran_text_styles.dart';
import '../../../models/mushaf_layout_info.dart';
import '../../../utils/mushaf_line_layout.dart';

/// One fixed-height mushaf line row with RTL text and user-controlled scaling.
class MushafLineSlot extends StatefulWidget {
  const MushafLineSlot({
    super.key,
    required this.line,
    required this.fontScale,
    this.paperTheme,
  });

  final MushafRenderedLine line;
  final double fontScale;
  final MushafPaperTheme? paperTheme;

  @override
  State<MushafLineSlot> createState() => _MushafLineSlotState();
}

class _MushafLineSlotState extends State<MushafLineSlot> {
  MushafLineMetrics? _metrics;
  TextSpan? _textSpan;
  double? _cachedWidth;
  double? _cachedHeight;
  double? _cachedFontScale;
  int? _cachedPaperColor;
  String? _cachedLineKey;

  void _resolveLayout({
    required double maxWidth,
    required double maxHeight,
    required TextScaler textScaler,
    required MushafPaperTheme theme,
  }) {
    final lineKey = '${widget.line.lineNumber}:${widget.line.text}';
    final paperColor = theme.paper.toARGB32();
    if (_metrics != null &&
        _cachedWidth == maxWidth &&
        _cachedHeight == maxHeight &&
        _cachedFontScale == widget.fontScale &&
        _cachedPaperColor == paperColor &&
        _cachedLineKey == lineKey) {
      return;
    }

    _cachedWidth = maxWidth;
    _cachedHeight = maxHeight;
    _cachedFontScale = widget.fontScale;
    _cachedPaperColor = paperColor;
    _cachedLineKey = lineKey;

    final contentWidth = widget.line.isSurahName
        ? maxWidth - (MushafTheme.surahBannerPaddingHForScale(widget.fontScale) * 2).w
        : maxWidth;

    _metrics = MushafLineLayout.resolveLineMetrics(
      line: widget.line,
      maxWidth: contentWidth,
      maxHeight: maxHeight,
      userScale: widget.fontScale,
      textScaler: textScaler,
      includeBanner: widget.line.isSurahName,
    );

    _textSpan = MushafLineLayout.buildTextSpan(
      line: widget.line,
      fontSize: _metrics!.fontSize,
      textColor: theme.ink,
      ayahMarkerColor: theme.ayahMarker,
      surahTitleColor: theme.surahTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.line.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = widget.paperTheme ?? MushafTheme.paperThemes.first;
    final textScaler = MediaQuery.textScalerOf(context);
    final bannerPadH = MushafTheme.surahBannerPaddingHForScale(widget.fontScale);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        if (maxWidth <= 0 || maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        _resolveLayout(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          textScaler: textScaler,
          theme: theme,
        );

        final metrics = _metrics!;
        final textSpan = _textSpan!;
        const alignment = Alignment.center;

        return RepaintBoundary(
          child: ClipRect(
            child: SizedBox(
              width: maxWidth,
              height: maxHeight,
              child: Align(
                alignment: alignment,
                child: _MushafLineText(
                  line: widget.line,
                  textSpan: textSpan,
                  textScaler: textScaler,
                  alignment: alignment,
                  banner: widget.line.isSurahName,
                  bannerPadH: bannerPadH,
                  verticalScale: metrics.verticalScale,
                  surahTitleColor: theme.surahTitle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MushafLineText extends StatelessWidget {
  const _MushafLineText({
    required this.line,
    required this.textSpan,
    required this.textScaler,
    required this.alignment,
    required this.bannerPadH,
    required this.verticalScale,
    required this.surahTitleColor,
    this.banner = false,
  });

  final MushafRenderedLine line;
  final TextSpan textSpan;
  final TextScaler textScaler;
  final Alignment alignment;
  final double bannerPadH;
  final double verticalScale;
  final Color surahTitleColor;
  final bool banner;

  @override
  Widget build(BuildContext context) {
    final richText = RichText(
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      textScaler: textScaler,
      textHeightBehavior: QuranTextStyles.textHeightBehavior,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
      text: textSpan,
    );

    Widget richTextWidget = richText;

    if (banner) {
      richTextWidget = Container(
        padding: EdgeInsets.symmetric(
          horizontal: bannerPadH.w,
          vertical: MushafTheme.surahBannerPaddingV.h,
        ),
        decoration: MushafTheme.surahBannerDecoration(
          borderColor: surahTitleColor,
        ),
        child: richTextWidget,
      );
    }

    if (verticalScale > 1.005) {
      richTextWidget = Transform(
        transform: Matrix4.diagonal3Values(1, verticalScale, 1),
        alignment: alignment,
        child: richTextWidget,
      );
    }

    return Semantics(
      label: line.text,
      excludeSemantics: true,
      child: richTextWidget,
    );
  }
}
