import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../constants/quran_text_styles.dart';
import '../../models/quran_surah.dart';
import '../../providers/quran_audio_provider.dart';
import '../../utils/quran_tap_targets.dart';

class SurahListTile extends ConsumerWidget {
  const SurahListTile({
    super.key,
    required this.surah,
    required this.onTap,
    required this.onPlay,
  });

  final QuranSurah surah;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final audio = ref.watch(quranAudioProvider);
    final notifier = ref.read(quranAudioProvider.notifier);

    final isThisSurah = audio.surahId == surah.id;
    final isLoading = isThisSurah && audio.isLoading;
    final isPlaying = isThisSurah && audio.isPlaying;

    void onPlayTap() {
      if (isThisSurah && (audio.isActive || audio.isLoading)) {
        if (audio.isLoading) return;
        notifier.togglePlayPause();
        return;
      }
      onPlay();
    }

    return CardContainer(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: AppColors.emeraldMid,
              borderRadius: BorderRadius.circular(AppRadius.md.r),
              border: Border.all(color: AppColors.cardBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              '${surah.id}',
              style: AppTextStyles.label(
                context,
              ).copyWith(color: AppColors.gold, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  surah.displayName(languageCode),
                  style: AppTextStyles.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                Text(
                  l10n.quranAyahs(surah.ayahCount),
                  style: AppTextStyles.bodySmall(context),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                surah.nameAr,
                style: QuranTextStyles.arabic(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm.r),
                ),
                child: Text(
                  surah.isMeccan ? l10n.quranMeccan : l10n.quranMedinan,
                  style: AppTextStyles.pill(context).copyWith(fontSize: 10.sp),
                ),
              ),
            ],
          ),
          SizedBox(width: 16.w),
          GestureDetector(
            onTap: onPlayTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: QuranTapTargets.minSize.r,
              height: QuranTapTargets.minSize.r,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 22.r,
                          height: 22.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold,
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          key: ValueKey(isPlaying),
                          color: AppColors.gold,
                          size: 28.r,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
