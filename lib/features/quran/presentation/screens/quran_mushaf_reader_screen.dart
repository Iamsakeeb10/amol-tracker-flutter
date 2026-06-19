import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../constants/quran_constants.dart';
import '../../providers/quran_audio_provider.dart';
import '../../providers/quran_page_provider.dart';
import '../../providers/quran_reading_prefs_provider.dart';
import '../../providers/quran_surah_provider.dart';
import '../widgets/mushaf_page_widget.dart';
import '../widgets/quran_audio_mini_bar.dart';
import '../widgets/translation_panel.dart';

class QuranMushafReaderScreen extends ConsumerStatefulWidget {
  const QuranMushafReaderScreen({
    super.key,
    this.initialPage = 1,
  });

  final int initialPage;

  @override
  ConsumerState<QuranMushafReaderScreen> createState() =>
      _QuranMushafReaderScreenState();
}

class _QuranMushafReaderScreenState
    extends ConsumerState<QuranMushafReaderScreen> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, QuranConstants.totalPages);
    _pageController = PageController(
      initialPage: _currentPage - 1,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    setState(() => _currentPage = page);
    ref.read(quranReadingPrefsProvider.notifier).setLastPage(page);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final audio = ref.watch(quranAudioProvider);
    final pageAyahsAsync = ref.watch(quranPageAyahsProvider(_currentPage));
    final pageSurahAsync = ref.watch(quranPageSurahProvider(_currentPage));
    final pageJuzAsync = ref.watch(quranPageJuzProvider(_currentPage));

    final surahName = pageSurahAsync.maybeWhen(
      data: (surah) => surah?.displayName(languageCode) ?? '',
      orElse: () => '',
    );
    final juz = pageJuzAsync.maybeWhen(
      data: (value) => value ?? 1,
      orElse: () => 1,
    );

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              surahName.isEmpty ? l10n.quranReader : surahName,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${l10n.quranPage(_currentPage)} • ${l10n.quranJuz(juz)}',
              style: AppTextStyles.bodySmall(context),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => showTranslationPanel(context),
            icon: Icon(Icons.translate_outlined, size: 22.r),
          ),
        ],
      ),
      bottomNavigationBar: const QuranAudioMiniBar(),
      body: Column(
        children: [
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: PageView.builder(
                reverse: true,
                controller: _pageController,
                itemCount: QuranConstants.totalPages,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final page = index + 1;
                  final ayahsAsync = ref.watch(quranPageAyahsProvider(page));
                  final surahAsync = ref.watch(quranPageSurahProvider(page));
                  return ayahsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text(error.toString())),
                    data: (ayahs) {
                      final surah = surahAsync.asData?.value;
                      return Directionality(
                        textDirection: TextDirection.ltr,
                        child: MushafPageWidget(
                          ayahs: ayahs,
                          surah: surah,
                          highlightedSurah: audio.surahId,
                          highlightedAyah: audio.ayah,
                          onAyahTap: (ayah) async {
                            final surahData = await ref.read(
                              quranSurahByIdProvider(ayah.surah).future,
                            );
                            if (surahData == null) return;
                            await ref.read(quranAudioProvider.notifier).playSurah(
                                  surahData,
                                  startAyah: ayah.ayah,
                                );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          if (pageAyahsAsync.hasValue &&
              ref.watch(quranReadingPrefsProvider).showTranslation)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
              decoration: BoxDecoration(
                color: AppColors.cardDark.withValues(alpha: 0.95),
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Text(
                pageAyahsAsync.value!
                        .map((a) => a.translation ?? '')
                        .where((t) => t.isNotEmpty)
                        .join('\n\n')
                        .trim()
                        .isEmpty
                    ? l10n.quranNoTranslation
                    : pageAyahsAsync.value!
                        .map((a) => a.translation ?? '')
                        .where((t) => t.isNotEmpty)
                        .join('\n\n'),
                style: AppTextStyles.bodySmall(context).copyWith(height: 1.5),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
