import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/bottom_tab_back_button.dart';
import '../../models/quran_surah.dart';
import '../../providers/quran_audio_provider.dart';
import '../../providers/quran_mushaf_provider.dart';
import '../../providers/quran_reading_prefs_provider.dart';
import '../../providers/quran_surah_provider.dart';
import '../../utils/quran_tap_targets.dart';
import '../widgets/mushaf_page_view.dart';
import '../widgets/quran_audio_mini_bar.dart';
import '../widgets/surah_list_tile.dart';

enum _QuranViewMode { surahList, mushafReader }

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  static const _searchAnimDuration = Duration(milliseconds: 280);
  static const _searchAnimCurve = Curves.easeOutCubic;
  static const _searchAnimReverseCurve = Curves.easeInCubic;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  bool _searchOpen = false;
  bool _searchTransitioning = false;
  String _searchQuery = '';
  late _QuranViewMode _viewMode;
  int _mushafCurrentPage = 1;

  double get _actionIconSize => 24.r;

  ButtonStyle get _actionIconStyle => QuranTapTargets.iconButtonStyle();

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(quranReadingPrefsProvider);
    _viewMode = prefs.mushafReaderMode
        ? _QuranViewMode.mushafReader
        : _QuranViewMode.surahList;
    _mushafCurrentPage = prefs.lastMushafPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      warmMushafResources(ref, centerPage: _mushafCurrentPage);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<QuranSurah> _filterSurahs(List<QuranSurah> surahs) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return surahs;
    return surahs
        .where(
          (s) =>
              s.nameAr.contains(_searchQuery.trim()) ||
              s.nameEn.toLowerCase().contains(q) ||
              s.nameBn.toLowerCase().contains(q) ||
              s.nameTransliteration.toLowerCase().contains(q) ||
              '${s.id}'.contains(q),
        )
        .toList(growable: false);
  }

  void _openSearch() {
    if (_searchTransitioning) return;
    _searchTransitioning = true;
    setState(() => _searchOpen = true);
    Future<void>.delayed(_searchAnimDuration, () {
      if (!mounted) return;
      _searchTransitioning = false;
      if (_searchOpen) _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    if (_searchTransitioning) return;
    _searchTransitioning = true;
    setState(() => _searchOpen = false);
    Future<void>.delayed(_searchAnimDuration, () {
      if (!mounted) return;
      _searchTransitioning = false;
      _searchController.clear();
      _searchFocusNode.unfocus();
      if (_searchQuery.isNotEmpty) {
        setState(() => _searchQuery = '');
      }
    });
  }

  void _onSearchAction() {
    if (_searchOpen) {
      _closeSearch();
    } else {
      _openSearch();
    }
  }

  void _onSearchChanged(String value) {
    final trimmed = value.trim();
    if (trimmed == _searchQuery) return;
    setState(() => _searchQuery = trimmed);
  }

  Future<void> _toggleViewMode() async {
    if (_searchOpen) _closeSearch();

    final nextMode = _viewMode == _QuranViewMode.surahList
        ? _QuranViewMode.mushafReader
        : _QuranViewMode.surahList;

    setState(() => _viewMode = nextMode);
    if (nextMode == _QuranViewMode.mushafReader) {
      warmMushafResources(ref, centerPage: _mushafCurrentPage);
    }
    await ref
        .read(quranReadingPrefsProvider.notifier)
        .setMushafReaderMode(nextMode == _QuranViewMode.mushafReader);
  }

  String _mushafAppBarTitle(AppLocalizations l10n) {
    final pageLabel = l10n.quranPage(_mushafCurrentPage);
    final surah =
        ref.watch(mushafPrimarySurahForPageProvider(_mushafCurrentPage));
    if (surah == null) return pageLabel;

    final languageCode = Localizations.localeOf(context).languageCode;
    return '${surah.displayName(languageCode)} · $pageLabel';
  }

  void _openMushafAtLastPage() {
    setState(() {
      _viewMode = _QuranViewMode.mushafReader;
      _mushafCurrentPage = ref.read(quranReadingPrefsProvider).lastMushafPage;
    });
    warmMushafResources(ref, centerPage: _mushafCurrentPage);
    unawaited(
      ref.read(quranReadingPrefsProvider.notifier).setMushafReaderMode(true),
    );
  }

  Widget _buildAppBarTitle(AppLocalizations l10n) {
    final titleStyle = AppTextStyles.headlineMedium(
      context,
    ).copyWith(fontSize: 17.5.sp, fontWeight: FontWeight.w600, height: 1);
    const titleHeightBehavior = TextHeightBehavior(
      applyHeightToFirstAscent: false,
      applyHeightToLastDescent: false,
    );

    final isMushaf = _viewMode == _QuranViewMode.mushafReader;
    final titleText = isMushaf
        ? _mushafAppBarTitle(l10n)
        : l10n.quranTitle;
    const titleIcon = Icons.auto_stories_rounded;

    return SizedBox(
      height: 42.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedSize(
            duration: _searchAnimDuration,
            curve: _searchAnimCurve,
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.hardEdge,
            child: _searchOpen || isMushaf
                ? const SizedBox.shrink()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        titleIcon,
                        size: _actionIconSize,
                        color: AppColors.gold,
                      ),
                      SizedBox(width: 8.w),
                    ],
                  ),
          ),
          Expanded(
            child: SizedBox(
              height: 42.h,
              child: AnimatedSwitcher(
                duration: _searchAnimDuration,
                switchInCurve: _searchAnimCurve,
                switchOutCurve: _searchAnimReverseCurve,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.centerLeft,
                    fit: StackFit.expand,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  final slideAnimation = Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: _searchAnimCurve,
                      reverseCurve: _searchAnimReverseCurve,
                    ),
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slideAnimation,
                      child: child,
                    ),
                  );
                },
                child: _searchOpen && !isMushaf
                    ? Align(
                        key: const ValueKey('quran_search_field'),
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          textInputAction: TextInputAction.search,
                          style: AppTextStyles.bodyLarge(
                            context,
                          ).copyWith(fontSize: 15.sp, height: 1),
                          strutStyle: const StrutStyle(
                            height: 1,
                            forceStrutHeight: true,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.quranSearchHint,
                            hintStyle: AppTextStyles.bodyMedium(
                              context,
                            ).copyWith(height: 1),
                            border: InputBorder.none,
                            isDense: true,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10.h,
                            ),
                          ),
                        ),
                      )
                    : Align(
                        key: ValueKey(
                          isMushaf ? 'quran_mushaf_title' : 'quran_title',
                        ),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            if (isMushaf) ...[
                              Icon(
                                titleIcon,
                                size: _actionIconSize,
                                color: AppColors.gold,
                              ),
                              SizedBox(width: 8.w),
                            ],
                            Expanded(
                              child: Text(
                                titleText,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: titleStyle,
                                textHeightBehavior: titleHeightBehavior,
                                strutStyle: const StrutStyle(
                                  height: 0,
                                  forceStrutHeight: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surahsAsync = ref.watch(quranSurahListProvider);
    final surahs = surahsAsync.asData?.value;
    final prefs = ref.watch(quranReadingPrefsProvider);
    final isMushaf = _viewMode == _QuranViewMode.mushafReader;

    return AppScaffold(
      padding: EdgeInsets.zero,
      handleExitBack: false,
      appBar: AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 42.h,
        leading: const BottomTabBackButton(fallbackRoute: AppRoutes.more),
        title: _buildAppBarTitle(l10n),
        actions: [
          IconButton(
            tooltip: isMushaf ? l10n.quranSurahMode : l10n.quranMushafMode,
            style: _actionIconStyle,
            onPressed: _toggleViewMode,
            icon: AnimatedSwitcher(
              duration: _searchAnimDuration,
              switchInCurve: _searchAnimCurve,
              switchOutCurve: _searchAnimReverseCurve,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.82, end: 1).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: _searchAnimCurve,
                        reverseCurve: _searchAnimReverseCurve,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: Icon(
                isMushaf
                    ? Icons.format_list_bulleted_rounded
                    : Icons.auto_stories_rounded,
                key: ValueKey(isMushaf),
                size: _actionIconSize,
              ),
            ),
          ),
          if (!isMushaf)
            IconButton(
              tooltip: _searchOpen ? l10n.cancel : l10n.quranSearchHint,
              style: _actionIconStyle,
              onPressed: _onSearchAction,
              icon: AnimatedSwitcher(
                duration: _searchAnimDuration,
                switchInCurve: _searchAnimCurve,
                switchOutCurve: _searchAnimReverseCurve,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.82, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: _searchAnimCurve,
                          reverseCurve: _searchAnimReverseCurve,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                  key: ValueKey(_searchOpen),
                  size: _actionIconSize,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const QuranAudioMiniBar(),
      body: isMushaf
          ? MushafPageView(
              onPageChanged: (page) {
                if (_mushafCurrentPage != page) {
                  setState(() => _mushafCurrentPage = page);
                }
              },
            )
          : surahsAsync.when(
              loading: () => surahs == null
                  ? const SizedBox.shrink()
                  : _SurahListView(
                      surahs: _filterSurahs(surahs),
                      lastMushafPage: prefs.lastMushafPage,
                      onContinueReading: _openMushafAtLastPage,
                      onTap: _openSurah,
                      onPlay: _playSurah,
                    ),
              error: (error, _) => Center(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Text(
                    error.toString(),
                    style: AppTextStyles.bodyMedium(context),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (allSurahs) => _SurahListView(
                surahs: _filterSurahs(allSurahs),
                lastMushafPage: prefs.lastMushafPage,
                onContinueReading: _openMushafAtLastPage,
                onTap: _openSurah,
                onPlay: _playSurah,
              ),
            ),
    );
  }

  void _openSurah(QuranSurah surah) {
    context.push(AppRoutes.quranSurahScrollPath(surah.id));
  }

  void _playSurah(QuranSurah surah) {
    context.push(AppRoutes.quranSurahScrollPath(surah.id));
    unawaited(ref.read(quranAudioProvider.notifier).playSurah(surah));
  }
}

class _SurahListView extends StatelessWidget {
  const _SurahListView({
    required this.surahs,
    required this.lastMushafPage,
    required this.onContinueReading,
    required this.onTap,
    required this.onPlay,
  });

  final List<QuranSurah> surahs;
  final int lastMushafPage;
  final VoidCallback onContinueReading;
  final ValueChanged<QuranSurah> onTap;
  final ValueChanged<QuranSurah> onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showContinueBanner = lastMushafPage > 1;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
      itemCount: surahs.length + (showContinueBanner ? 1 : 0),
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        if (showContinueBanner && index == 0) {
          return _ContinueReadingBanner(
            label: l10n.quranContinueReading(lastMushafPage),
            actionLabel: l10n.quranOpenReader,
            onTap: onContinueReading,
          );
        }

        final surahIndex = showContinueBanner ? index - 1 : index;
        final surah = surahs[surahIndex];
        return SurahListTile(
          surah: surah,
          onTap: () => onTap(surah),
          onPlay: () => onPlay(surah),
        );
      },
    );
  }
}

class _ContinueReadingBanner extends StatelessWidget {
  const _ContinueReadingBanner({
    required this.label,
    required this.actionLabel,
    required this.onTap,
  });

  final String label;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_stories_rounded, color: AppColors.gold, size: 22.r),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              actionLabel,
              style: AppTextStyles.label(context).copyWith(
                color: AppColors.gold,
                letterSpacing: 0.4,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right_rounded, color: AppColors.gold, size: 20.r),
          ],
        ),
      ),
    );
  }
}
