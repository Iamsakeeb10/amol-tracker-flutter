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
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    if (!audio.isActive && !audio.isLoading) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 8,
      color: AppColors.emeraldMid,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      audio.surahName.isEmpty
                          ? l10n.quranTitle
                          : audio.surahName,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${l10n.quranAyahLabel(audio.ayah)} • ${isBn ? qari.nameBn : qari.nameEn}',
                      style: AppTextStyles.bodySmall(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: notifier.previousAyah,
                icon: Icon(Icons.skip_previous_rounded, size: 24.r),
              ),
              IconButton(
                onPressed: audio.isLoading ? null : notifier.togglePlayPause,
                icon: audio.isLoading
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        audio.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: AppColors.gold,
                        size: 32.r,
                      ),
              ),
              IconButton(
                onPressed: notifier.nextAyah,
                icon: Icon(Icons.skip_next_rounded, size: 24.r),
              ),
              IconButton(
                onPressed: () => showQariSelectorSheet(context),
                icon: Icon(Icons.person_outline, size: 22.r),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
