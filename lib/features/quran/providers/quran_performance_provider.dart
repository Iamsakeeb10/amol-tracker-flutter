import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/device_tier_service.dart';
import '../../../providers/device_tier_provider.dart';

/// Tier-derived performance tunables for the Quran surah-list and scroll paths.
class QuranPerformanceProfile {
  const QuranPerformanceProfile({
    required this.surahScrollCacheExtent,
    required this.reduceMotion,
  });

  final double surahScrollCacheExtent;
  final bool reduceMotion;

  static QuranPerformanceProfile forTier(DeviceTier tier) => switch (tier) {
        DeviceTier.low => const QuranPerformanceProfile(
            surahScrollCacheExtent: 400,
            reduceMotion: true,
          ),
        DeviceTier.medium => const QuranPerformanceProfile(
            surahScrollCacheExtent: 800,
            reduceMotion: false,
          ),
        DeviceTier.high => const QuranPerformanceProfile(
            surahScrollCacheExtent: 1200,
            reduceMotion: false,
          ),
      };

  static const medium = QuranPerformanceProfile(
    surahScrollCacheExtent: 800,
    reduceMotion: false,
  );
}

final quranPerformanceProvider = Provider<QuranPerformanceProfile>((ref) {
  final tier = ref.watch(deviceTierProvider).asData?.value;
  if (tier == null) return QuranPerformanceProfile.medium;
  return QuranPerformanceProfile.forTier(tier);
});
