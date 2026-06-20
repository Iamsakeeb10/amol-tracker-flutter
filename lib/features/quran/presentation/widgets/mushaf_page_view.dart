import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/quran_constants.dart';
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
  late final ValueNotifier<int> _pageNotifier;
  late final ValueNotifier<int> _juzNotifier;
  int _totalPages = QuranConstants.mushafPageCount;
  bool _overlayVisible = false;
  Timer? _persistDebounce;
  Timer? _prefetchDebounce;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(quranReadingPrefsProvider);
    final initialPage =
        prefs.lastMushafPage.clamp(1, QuranConstants.mushafPageCount);
    _pageNotifier = ValueNotifier(initialPage);
    _juzNotifier = ValueNotifier(1);
    widget.onPageChanged(initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      warmMushafResources(ref, centerPage: initialPage);
      _loadJuzForPage(initialPage);
    });
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
    _prefetchDebounce?.cancel();
    _pageNotifier.dispose();
    _juzNotifier.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  void _ensureController(int totalPages) {
    final currentPage = _pageNotifier.value;
    final initialPage = currentPage.clamp(1, totalPages) - 1;
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
    if (_pageNotifier.value == page) return;

    _pageNotifier.value = page;
    widget.onPageChanged(page);

    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(quranReadingPrefsProvider.notifier).setLastMushafPage(page);
    });

    _loadJuzForPage(page);

    _prefetchDebounce?.cancel();
    _prefetchDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      warmMushafResources(ref, centerPage: page, radius: 3);
    });
  }

  Future<void> _loadJuzForPage(int page) async {
    final pageData = ref.read(mushafPageCacheProvider)[page];
    if (pageData != null) {
      _juzNotifier.value = pageData.juz;
      return;
    }

    await ref.read(mushafPageCacheProvider.notifier).ensurePage(page);
    if (!mounted) return;
    final loaded = ref.read(mushafPageCacheProvider)[page];
    if (loaded != null) {
      _juzNotifier.value = loaded.juz;
    }
  }

  void _jumpToPage(int page) {
    final clamped = page.clamp(1, _totalPages);
    final controller = _pageController;
    if (controller == null || !controller.hasClients) {
      _pageNotifier.value = clamped;
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

    final totalPages =
        pageCountAsync.asData?.value ?? QuranConstants.mushafPageCount;

    if (pageCountAsync.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pageCountAsync.error.toString()),
            TextButton(
              onPressed: () => ref.invalidate(quranPageCountProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

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
                  physics: const PageScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  itemBuilder: (context, index) {
                    return MushafPageWidget(
                      key: ValueKey('mushaf-page-${index + 1}'),
                      pageNumber: index + 1,
                    );
                  },
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: _pageNotifier,
                builder: (context, currentPage, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: _juzNotifier,
                    builder: (context, currentJuz, _) {
                      return MushafOverlayControls(
                        currentPage: currentPage,
                        totalPages: totalPages,
                        currentJuz: currentJuz,
                        visible: _overlayVisible,
                        onToggleVisibility: _toggleOverlay,
                        onJumpToPage: _jumpToPage,
                        onInteraction: () {},
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: _pageNotifier,
          builder: (context, currentPage, _) {
            return AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: showTranslation
                  ? MushafTranslationStrip(pageNumber: currentPage)
                  : const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }
}
