import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../models/quran_surah.dart';
import '../../providers/quran_audio_provider.dart';
import '../../providers/quran_reading_prefs_provider.dart';
import '../../providers/quran_surah_provider.dart';
import '../widgets/surah_list_tile.dart';

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QuranSurah> _filterSurahs(List<QuranSurah> surahs) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return surahs;
    return surahs
        .where(
          (s) =>
              s.nameAr.contains(_query.trim()) ||
              s.nameEn.toLowerCase().contains(q) ||
              s.nameBn.toLowerCase().contains(q) ||
              s.nameTransliteration.toLowerCase().contains(q) ||
              '${s.id}'.contains(q),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surahsAsync = ref.watch(quranSurahListProvider);
    final prefs = ref.watch(quranReadingPrefsProvider);
    final surahs = surahsAsync.asData?.value;

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.quranTitle, style: AppTextStyles.headlineMedium(context)),
        actions: [
          IconButton(
            tooltip: l10n.quranReader,
            onPressed: () => context.push(
              '${AppRoutes.quranReader}?page=${prefs.lastPage}',
            ),
            icon: Icon(Icons.menu_book_outlined, size: 22.r),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: AppTextStyles.bodyMedium(context),
              decoration: InputDecoration(
                hintText: l10n.quranSearchHint,
                prefixIcon: Icon(Icons.search, size: 20.r),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg.r),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg.r),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: CardContainer(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                children: [
                  Icon(Icons.bookmark_outline, color: AppColors.gold, size: 18.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      l10n.quranContinueReading(prefs.lastPage),
                      style: AppTextStyles.bodySmall(context),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(
                      '${AppRoutes.quranReader}?page=${prefs.lastPage}',
                    ),
                    child: Text(l10n.quranOpenReader),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: surahsAsync.when(
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
          ),
        ],
      ),
    );
  }

  void _openSurah(QuranSurah surah) {
    context.push('${AppRoutes.quranReader}?page=${surah.startPage}');
  }

  Future<void> _playSurah(QuranSurah surah) async {
    await ref.read(quranAudioProvider.notifier).playSurah(surah);
    if (!mounted) return;
    context.push(AppRoutes.quranSurahScrollPath(surah.id));
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
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
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
