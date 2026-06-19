import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../constants/quran_constants.dart';
import '../../providers/quran_audio_provider.dart';
import '../../providers/quran_reading_prefs_provider.dart';
import 'qari_selector_sheet.dart';

class QuranAudioMiniBar extends ConsumerWidget {
  const QuranAudioMiniBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final audio = ref.watch(quranAudioProvider);
    final prefs = ref.watch(quranReadingPrefsProvider);
    final notifier = ref.read(quranAudioProvider.notifier);
    final qari = QuranConstants.qariById(prefs.qari);
    final languageCode = Localizations.localeOf(context).languageCode;
    final isBn = languageCode == 'bn';

    if (!audio.isActive && !audio.isLoading) {
      return const SizedBox.shrink();
    }

    final progress = audio.totalAyahs > 0 ? audio.ayah / audio.totalAyahs : 0.0;
    final displayName = audio.displayName(languageCode);
    final ayahProgress = audio.totalAyahs > 0
        ? '${l10n.quranAyahLabel(audio.ayah)} / ${audio.totalAyahs}'
        : l10n.quranAyahLabel(audio.ayah);

    return Material(
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      color: AppColors.emeraldMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3.h,
              backgroundColor: AppColors.gold.withValues(alpha: 0.15),
              color: AppColors.gold,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 8.w, 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName.isEmpty ? l10n.quranTitle : displayName,
                          style: AppTextStyles.bodyLarge(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '$ayahProgress • ${isBn ? qari.nameBn : qari.nameEn}',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.gold.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: audio.isLoading ? null : notifier.previousAyah,
                    icon: Icon(Icons.skip_previous_rounded, size: 26.r),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: audio.isLoading ? null : notifier.togglePlayPause,
                    icon: audio.isLoading
                        ? SizedBox(
                            width: 24.r,
                            height: 24.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.gold,
                            ),
                          )
                        : Icon(
                            audio.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: AppColors.gold,
                            size: 36.r,
                          ),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: audio.isLoading ? null : notifier.nextAyah,
                    icon: Icon(Icons.skip_next_rounded, size: 26.r),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () => showQariSelectorSheet(context),
                    icon: Icon(Icons.person_outline_rounded, size: 22.r),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: audio.isLoading ? null : notifier.stop,
                    icon: Icon(Icons.close_rounded, size: 22.r),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
