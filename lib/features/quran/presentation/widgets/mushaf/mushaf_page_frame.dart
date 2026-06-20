import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/mushaf_theme.dart';
import '../../../constants/quran_text_styles.dart';
import '../../../utils/mushaf_formatters.dart';

/// Cream paper card with optional footer page number — mimics a printed mushaf page.
class MushafPageFrame extends StatelessWidget {
  const MushafPageFrame({
    super.key,
    required this.pageNumber,
    required this.body,
    this.outerPaddingH = MushafTheme.pageOuterPaddingH,
    this.fontScale = 1.0,
  });

  final int pageNumber;
  final Widget body;
  final double outerPaddingH;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final radius = MushafTheme.pageBorderRadius.r;
    final footerHeight = MushafTheme.pageFooterHeightForScale(fontScale);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        outerPaddingH.w,
        MushafTheme.pageOuterPaddingV.h,
        outerPaddingH.w,
        MushafTheme.pageOuterPaddingV.h,
      ),
      child: DecoratedBox(
        decoration: MushafTheme.pageDecoration(borderRadius: radius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: Clip.antiAlias,
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
                        color: MushafTheme.pageNumber,
                      ),
                      textHeightBehavior: QuranTextStyles.textHeightBehavior,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
