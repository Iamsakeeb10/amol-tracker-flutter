import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../dua/presentation/widgets/dua_floating_audio_button.dart';
import '../../providers/quran_audio_provider.dart';
import '../../providers/quran_surah_provider.dart';

/// Margin for positioning — shared with [DuaFloatingAudioButton].
const double kQuranFloatingAudioButtonMargin = kDuaFloatingAudioButtonMargin;

/// Floating play button for surah recitation — matches [DuaFloatingAudioButton].
class QuranFloatingAudioButton extends ConsumerWidget {
  const QuranFloatingAudioButton({
    super.key,
    required this.surahId,
  });

  final int surahId;

  Future<void> _onTap(WidgetRef ref) async {
    final surah = await ref.read(quranSurahByIdProvider(surahId).future);
    if (surah == null) return;
    await ref.read(quranAudioProvider.notifier).playSurah(surah);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(quranAudioProvider);
    final isLoading =
        audio.isLoading && (audio.surahId == surahId || audio.surahId == 0);

    return Material(
      elevation: 6,
      shadowColor: AppColors.emeraldDeep.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      color: AppColors.emeraldMid,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isLoading ? null : () => _onTap(ref),
        child: SizedBox(
          width: kDuaFloatingAudioButtonSize.r,
          height: kDuaFloatingAudioButtonSize.r,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24.r,
                    height: 24.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5.r,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Bottom [ListView] padding when the floating play button is visible.
double quranSurahScrollBottomPadding({required bool showFloatingAudioButton}) {
  if (!showFloatingAudioButton) return 120.h;
  return kDuaFloatingAudioButtonMargin.h +
      kDuaFloatingAudioButtonSize.r +
      kDuaFloatingAudioScrollClearance.h;
}
