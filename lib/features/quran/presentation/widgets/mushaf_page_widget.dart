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
    final fontScale = ref.watch(
      quranReadingPrefsProvider.select((prefs) => prefs.arabicFontScale),
    );
    final pageAsync = ref.watch(
      quranMushafPageProvider(MushafPageQuery(page: pageNumber)),
    );

    return pageAsync.when(
      loading: () => const _MushafPageSkeleton(),
      error: (error, _) => _MushafPageError(
        message: error.toString(),
        onRetry: () => ref.invalidate(
          quranMushafPageProvider(MushafPageQuery(page: pageNumber)),
        ),
      ),
      data: (pageData) => _MushafPageContent(
        pageData: pageData,
        fontScale: fontScale,
      ),
    );
  }
}

class _MushafPageContent extends StatelessWidget {
  const _MushafPageContent({
    required this.pageData,
    required this.fontScale,
  });

  final QuranMushafPageData pageData;
  final double fontScale;

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
    final outerPad = MushafTheme.outerPaddingHForScale(fontScale);
    final innerTop = MushafTheme.innerPaddingTopForScale(fontScale);

    return Semantics(
      label: l10n.quranPage(pageData.page),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: MushafPageFrame(
          pageNumber: pageData.page,
          outerPaddingH: outerPad,
          fontScale: fontScale,
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
                      key: ValueKey('${pageData.page}-${line.lineNumber}-$fontScale'),
                      line: line,
                      fontScale: fontScale,
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
  const _MushafPageSkeleton();

  @override
  Widget build(BuildContext context) {
    final radius = MushafTheme.pageBorderRadius.r;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        MushafTheme.pageOuterPaddingH.w,
        MushafTheme.pageOuterPaddingV.h,
        MushafTheme.pageOuterPaddingH.w,
        MushafTheme.pageOuterPaddingV.h,
      ),
      child: Shimmer.fromColors(
        baseColor: MushafTheme.paperBorder.withValues(alpha: 0.4),
        highlightColor: MushafTheme.paper,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: MushafTheme.paper,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              children: List.generate(
                15,
                (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 2.h),
                    color: MushafTheme.paperBorder.withValues(alpha: 0.25),
                  ),
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
