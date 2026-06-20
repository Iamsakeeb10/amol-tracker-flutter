import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../constants/mushaf_theme.dart';
import '../../models/quran_mushaf_page_data.dart';
import '../../providers/quran_mushaf_provider.dart';
import '../../providers/quran_reading_prefs_provider.dart';
import 'mushaf/mushaf_line_slot.dart';
import 'mushaf/mushaf_page_frame.dart';

/// Single mushaf page (610-page Indo-Pak 15-line layout).
class MushafPageWidget extends ConsumerStatefulWidget {
  const MushafPageWidget({
    super.key,
    required this.pageNumber,
  });

  final int pageNumber;

  @override
  ConsumerState<MushafPageWidget> createState() => _MushafPageWidgetState();
}

class _MushafPageWidgetState extends ConsumerState<MushafPageWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _ensurePage();
  }

  @override
  void didUpdateWidget(MushafPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _ensurePage();
    }
  }

  void _ensurePage() {
    ref.read(mushafPageCacheProvider.notifier).ensurePage(widget.pageNumber);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final fontScale = ref.watch(
      quranReadingPrefsProvider.select((prefs) => prefs.arabicFontScale),
    );
    final mushafBgIndex = ref.watch(
      quranReadingPrefsProvider.select((prefs) => prefs.mushafBgIndex),
    );
    final paperTheme = MushafTheme.themeAt(mushafBgIndex);
    final pageData = ref.watch(
      mushafPageCacheProvider.select((cache) => cache[widget.pageNumber]),
    );

    if (pageData == null) {
      return _MushafPagePlaceholder(
        pageNumber: widget.pageNumber,
        fontScale: fontScale,
        paperTheme: paperTheme,
      );
    }

    return RepaintBoundary(
      child: _MushafPageContent(
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

/// Empty page shell shown while local DB data is read — no spinner or shimmer.
class _MushafPagePlaceholder extends StatelessWidget {
  const _MushafPagePlaceholder({
    required this.pageNumber,
    required this.fontScale,
    required this.paperTheme,
  });

  final int pageNumber;
  final double fontScale;
  final MushafPaperTheme paperTheme;

  @override
  Widget build(BuildContext context) {
    final innerPad = MushafTheme.innerPaddingHForScale(fontScale);
    final innerTop = MushafTheme.innerPaddingTopForScale(fontScale);

    return MushafPageFrame(
      pageNumber: pageNumber,
      fontScale: fontScale,
      paperTheme: paperTheme,
      body: Padding(
        padding: EdgeInsets.fromLTRB(innerPad.w, innerTop.h, innerPad.w, 0),
        child: Column(
          children: List.generate(
            15,
            (_) => const Expanded(child: SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}
