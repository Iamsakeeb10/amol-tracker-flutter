import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../models/quran_audio_state.dart';
import '../../providers/quran_audio_provider.dart';
import '../../providers/quran_surah_ayahs_provider.dart';
import '../../providers/quran_surah_provider.dart';
import '../widgets/ayah_card_widget.dart';
import '../widgets/quran_audio_mini_bar.dart';
import '../widgets/translation_panel.dart';

class QuranSurahScrollScreen extends ConsumerStatefulWidget {
  const QuranSurahScrollScreen({
    super.key,
    required this.surahId,
  });

  final int surahId;

  @override
  ConsumerState<QuranSurahScrollScreen> createState() =>
      _QuranSurahScrollScreenState();
}

class _QuranSurahScrollScreenState extends ConsumerState<QuranSurahScrollScreen> {
  final _scrollController = ScrollController();
  final _ayahKeys = <int, GlobalKey>{};
  int? _lastScrolledAyah;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyForAyah(int ayah) =>
      _ayahKeys.putIfAbsent(ayah, GlobalKey.new);

  void _scrollToAyah(int ayah) {
    if (_lastScrolledAyah == ayah) return;
    _lastScrolledAyah = ayah;
    final key = _ayahKeys[ayah];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.35,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final surahAsync = ref.watch(quranSurahByIdProvider(widget.surahId));
    final ayahsAsync = ref.watch(quranSurahAyahsProvider(widget.surahId));
    final audio = ref.watch(quranAudioProvider);

    ref.listen<QuranAudioState>(quranAudioProvider, (previous, next) {
      if (next.surahId != widget.surahId || next.ayah <= 0) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToAyah(next.ayah);
      });
    });

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: surahAsync.when(
          data: (surah) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                surah?.displayName(languageCode) ?? l10n.quranTitle,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (surah != null)
                Text(
                  l10n.quranAyahs(surah.ayahCount),
                  style: AppTextStyles.bodySmall(context),
                ),
            ],
          ),
          loading: () => Text(l10n.quranTitle),
          error: (_, __) => Text(l10n.quranTitle),
        ),
        actions: [
          IconButton(
            onPressed: () => showTranslationPanel(context),
            icon: Icon(Icons.translate_outlined, size: 22.r),
          ),
          IconButton(
            onPressed: () async {
              final surah = await ref.read(
                quranSurahByIdProvider(widget.surahId).future,
              );
              if (surah == null) return;
              await ref.read(quranAudioProvider.notifier).playSurah(surah);
            },
            icon: Icon(Icons.play_arrow_rounded, size: 24.r, color: AppColors.gold),
          ),
        ],
      ),
      bottomNavigationBar: const QuranAudioMiniBar(),
      floatingActionButton: audio.isActive
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.emeraldMid,
              onPressed: () async {
                final surah = await ref.read(
                  quranSurahByIdProvider(widget.surahId).future,
                );
                if (surah == null) return;
                await ref.read(quranAudioProvider.notifier).playSurah(surah);
              },
              child: Icon(Icons.play_arrow_rounded, color: AppColors.gold, size: 28.r),
            ),
      body: ayahsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (ayahs) {
          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 120.h),
            itemCount: ayahs.length,
            itemBuilder: (context, index) {
              final ayah = ayahs[index];
              final highlighted =
                  audio.surahId == widget.surahId && audio.ayah == ayah.ayah;
              return KeyedSubtree(
                key: _keyForAyah(ayah.ayah),
                child: AyahCardWidget(
                  ayah: ayah,
                  highlighted: highlighted,
                  onTap: () async {
                    final surah = await ref.read(
                      quranSurahByIdProvider(widget.surahId).future,
                    );
                    if (surah == null) return;
                    await ref.read(quranAudioProvider.notifier).playSurah(
                          surah,
                          startAyah: ayah.ayah,
                        );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
