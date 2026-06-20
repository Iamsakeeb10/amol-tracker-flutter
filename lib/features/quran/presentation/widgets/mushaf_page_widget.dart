import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../constants/mushaf_theme.dart';
import '../../models/quran_mushaf_page_data.dart';
import '../../providers/quran_mushaf_provider.dart';
import '../../providers/quran_reading_prefs_provider.dart';
import 'mushaf/mushaf_line_slot.dart';
import 'mushaf/mushaf_page_frame.dart';

/// Single mushaf page (610-page Indo-Pak 15-line layout).
class MushafPageWidget extends ConsumerWidget {
  const MushafPageWidget({
    super.key,
    required this.pageNumber,
  });

  final int pageNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(quranReadingPrefsProvider);
    final fontScale = prefs.arabicFontScale;
    final paperTheme = MushafTheme.themeAt(prefs.mushafBgIndex);
    final pageAsync = ref.watch(
      quranMushafPageProvider(MushafPageQuery(page: pageNumber)),
    );

    return pageAsync.when(
      loading: () => _MushafPageSkeleton(paperTheme: paperTheme),
      error: (error, _) => _MushafPageError(
        message: error.toString(),
        onRetry: () => ref.invalidate(
          quranMushafPageProvider(MushafPageQuery(page: pageNumber)),
        ),
      ),
      data: (pageData) => _MushafPageContent(
        pageData: pageData,
        fontScale: fontScale,
        paperTheme: paperTheme,
      ),
    );
  }
}

class _MushafPageContent extends StatelessWidget {
  const _MushafPageContent({
    required this.pageData,
    required this.fontScale,
    required this.paperTheme,
  });

  final QuranMushafPageData pageData;
  final double fontScale;
  final MushafPaperTheme paperTheme;

  @override
  Widget build(BuildContext context) {
    final lines = pageData.lines;
    final l10n = AppLocalizations.of(context)!;

    if (lines.isEmpty) {
      return Center(
        child: Text(
          l10n.quranPage(pageData.page),
          style: AppTextStyles.bodyMedium(context),
        ),
      );
    }

    final slotCount = lines.length > pageData.linesPerPage
        ? lines.length
        : pageData.linesPerPage;
    final blankLineCount = slotCount - lines.length;

    final innerPad = MushafTheme.innerPaddingHForScale(fontScale);
    final innerTop = MushafTheme.innerPaddingTopForScale(fontScale);

    return Semantics(
      label: l10n.quranPage(pageData.page),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: MushafPageFrame(
          pageNumber: pageData.page,
          fontScale: fontScale,
          paperTheme: paperTheme,
          body: Padding(
            padding: EdgeInsets.fromLTRB(
              innerPad.w,
              innerTop.h,
              innerPad.w,
              0,
            ),
            child: Column(
              children: [
                for (final line in lines)
                  Expanded(
                    child: MushafLineSlot(
                      key: ValueKey(
                        '${pageData.page}-${line.lineNumber}-$fontScale-${paperTheme.paper.toARGB32()}',
                      ),
                      line: line,
                      fontScale: fontScale,
                      paperTheme: paperTheme,
                    ),
                  ),
                for (var i = 0; i < blankLineCount; i++)
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MushafPageSkeleton extends StatelessWidget {
  const _MushafPageSkeleton({required this.paperTheme});

  final MushafPaperTheme paperTheme;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: paperTheme.paperBorder.withValues(alpha: 0.4),
      highlightColor: paperTheme.paper,
      child: DecoratedBox(
        decoration: MushafTheme.pageDecoration(
          borderRadius: 0,
          paperColor: paperTheme.paper,
          fullBleed: true,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MushafTheme.pageInnerPaddingH.w,
            MushafTheme.pageInnerPaddingTop.h,
            MushafTheme.pageInnerPaddingH.w,
            0,
          ),
          child: Column(
            children: List.generate(
              15,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 2.h),
                  color: paperTheme.paperBorder.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MushafPageError extends StatelessWidget {
  const _MushafPageError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.gold, size: 36.r),
            SizedBox(height: 12.h),
            Text(
              message,
              style: AppTextStyles.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.husnaRetryQuiz),
            ),
          ],
        ),
      ),
    );
  }
}
