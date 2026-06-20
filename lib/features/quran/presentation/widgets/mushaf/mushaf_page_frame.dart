import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/mushaf_theme.dart';
import '../../../constants/quran_text_styles.dart';
import '../../../utils/mushaf_formatters.dart';

/// Full-bleed mushaf page with paper background and optional footer page number.
class MushafPageFrame extends StatelessWidget {
  const MushafPageFrame({
    super.key,
    required this.pageNumber,
    required this.body,
    this.fontScale = 1.0,
    this.paperTheme,
  });

  final int pageNumber;
  final Widget body;
  final double fontScale;
  final MushafPaperTheme? paperTheme;

  @override
  Widget build(BuildContext context) {
    final theme = paperTheme ?? MushafTheme.paperThemes.first;
    final footerHeight = MushafTheme.pageFooterHeightForScale(fontScale);

    return DecoratedBox(
      decoration: MushafTheme.pageDecoration(
        borderRadius: 0,
        paperColor: theme.paper,
        fullBleed: true,
      ),
      child: Column(
        children: [
          Expanded(child: body),
          SizedBox(
            height: footerHeight.h,
            child: Center(
              child: Semantics(
                label: mushafArabicIndicDigits(pageNumber),
                child: Text(
                  mushafArabicIndicDigits(pageNumber),
                  style: QuranTextStyles.mushaf(
                    fontSize: MushafTheme.pageNumberFontSize.sp,
                    color: theme.pageNumber,
                  ),
                  textHeightBehavior: QuranTextStyles.textHeightBehavior,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
