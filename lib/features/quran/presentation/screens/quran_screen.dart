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
import '../../models/quran_surah.dart';
import '../../providers/quran_audio_provider.dart';
import '../../providers/quran_surah_provider.dart';
import '../widgets/surah_list_tile.dart';

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

  double get _actionIconSize => 24.r;

  ButtonStyle get _actionIconStyle => IconButton.styleFrom(
        padding: EdgeInsets.all(10.r),
        minimumSize: Size(44.r, 44.r),
        tapTargetSize: MaterialTapTargetSize.padded,
      );

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

  Widget _buildAppBarTitle(AppLocalizations l10n) {
    final titleStyle = AppTextStyles.headlineMedium(
      context,
    ).copyWith(fontSize: 17.5.sp, fontWeight: FontWeight.w600, height: 1);
    const titleHeightBehavior = TextHeightBehavior(
      applyHeightToFirstAscent: false,
      applyHeightToLastDescent: false,
    );

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
            child: _searchOpen
                ? const SizedBox.shrink()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
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
                child: _searchOpen
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
                        key: const ValueKey('quran_title'),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.quranTitle,
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

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 42.h,
        title: _buildAppBarTitle(l10n),
        actions: [
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
      body: surahsAsync.when(
        loading: () => surahs == null
            ? const SizedBox.shrink()
            : _SurahListView(
                surahs: _filterSurahs(surahs),
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
    required this.onTap,
    required this.onPlay,
  });

  final List<QuranSurah> surahs;
  final ValueChanged<QuranSurah> onTap;
  final ValueChanged<QuranSurah> onPlay;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
      itemCount: surahs.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final surah = surahs[index];
        return SurahListTile(
          surah: surah,
          onTap: () => onTap(surah),
          onPlay: () => onPlay(surah),
        );
      },
    );
  }
}
