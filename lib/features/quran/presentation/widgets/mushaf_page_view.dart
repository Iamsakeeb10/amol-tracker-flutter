import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/quran_constants.dart';
import '../../models/quran_reading_prefs.dart';
import '../../providers/quran_mushaf_provider.dart';
import '../../providers/quran_reading_prefs_provider.dart';
import 'mushaf/mushaf_translation_strip.dart';
import 'mushaf_overlay_controls.dart';
import 'mushaf_page_widget.dart';

/// Horizontal page reader for the 610-page mushaf layout.
class MushafPageView extends ConsumerStatefulWidget {
  const MushafPageView({
    super.key,
    required this.onPageChanged,
  });

  final ValueChanged<int> onPageChanged;

  @override
  ConsumerState<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends ConsumerState<MushafPageView> {
  PageController? _pageController;
  int _currentPage = 1;
  int _totalPages = QuranConstants.mushafPageCount;
  int _currentJuz = 1;
  bool _overlayVisible = false;
  Timer? _persistDebounce;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(quranReadingPrefsProvider);
    _currentPage = prefs.lastMushafPage.clamp(1, QuranConstants.mushafPageCount);
    widget.onPageChanged(_currentPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadJuzForPage(_currentPage);
      _prefetchAdjacentPages(_currentPage);
    });
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  void _ensureController(int totalPages) {
    final initialPage = _currentPage.clamp(1, totalPages) - 1;
    if (_pageController != null &&
        _pageController!.hasClients &&
        _totalPages == totalPages) {
      return;
    }
    _pageController?.dispose();
    _pageController = PageController(initialPage: initialPage);
    _totalPages = totalPages;
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    if (_currentPage == page) return;

    setState(() => _currentPage = page);
    widget.onPageChanged(page);

    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(quranReadingPrefsProvider.notifier).setLastMushafPage(page);
    });

    _loadJuzForPage(page);
    _prefetchAdjacentPages(page);
  }

  void _prefetchAdjacentPages(int page) {
    final translator = ref.read(quranReadingPrefsProvider).translator.dbKey;
    for (final adjacent in [page - 1, page + 1]) {
      if (adjacent < 1 || adjacent > _totalPages) continue;
      unawaited(
        ref.read(
          quranMushafPageProvider(MushafPageQuery(page: adjacent)).future,
        ),
      );
      unawaited(
        ref.read(
          quranMushafPageAyahsProvider(
            MushafPageAyahsQuery(page: adjacent, translator: translator),
          ).future,
        ),
      );
    }
  }

  Future<void> _loadJuzForPage(int page) async {
    final pageData = await ref.read(
      quranMushafPageProvider(MushafPageQuery(page: page)).future,
    );
    if (!mounted) return;
    setState(() => _currentJuz = pageData.juz);
  }

  void _jumpToPage(int page) {
    final clamped = page.clamp(1, _totalPages);
    final controller = _pageController;
    if (controller == null || !controller.hasClients) {
      setState(() => _currentPage = clamped);
      widget.onPageChanged(clamped);
      return;
    }
    controller.animateToPage(
      clamped - 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleOverlay() {
    setState(() => _overlayVisible = !_overlayVisible);
  }

  @override
  Widget build(BuildContext context) {
    final pageCountAsync = ref.watch(quranPageCountProvider);
    final showTranslation = ref.watch(
      quranReadingPrefsProvider.select((prefs) => prefs.showTranslation),
    );

    return pageCountAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error.toString()),
            TextButton(
              onPressed: () => ref.invalidate(quranPageCountProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (totalPages) {
        _ensureController(totalPages);

        return Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: totalPages,
                      onPageChanged: _onPageChanged,
                      allowImplicitScrolling: true,
                      itemBuilder: (context, index) {
                        final page = index + 1;
                        return MushafPageWidget(
                          key: ValueKey('mushaf-page-$page'),
                          pageNumber: page,
                        );
                      },
                    ),
                  ),
                  MushafOverlayControls(
                    currentPage: _currentPage,
                    totalPages: totalPages,
                    currentJuz: _currentJuz,
                    visible: _overlayVisible,
                    onToggleVisibility: _toggleOverlay,
                    onJumpToPage: _jumpToPage,
                    onInteraction: () {},
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: showTranslation
                  ? MushafTranslationStrip(pageNumber: _currentPage)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
