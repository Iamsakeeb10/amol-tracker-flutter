import '../../l10n/app_localizations.dart';

class LmsLevelTier {
  const LmsLevelTier({
    required this.index,
    required this.xpThreshold,
    required this.titleEn,
    required this.titleBn,
    required this.iconName,
  });

  final int index;
  final int xpThreshold;
  final String titleEn;
  final String titleBn;
  final String iconName;
}

const List<LmsLevelTier> kLmsLevelTiers = [
  LmsLevelTier(
    index: 0,
    xpThreshold: 0,
    titleEn: 'Beginner (Mubtadi)',
    titleBn: 'নবীন (মুবতাদি)',
    iconName: 'seedling',
  ),
  LmsLevelTier(
    index: 1,
    xpThreshold: 50,
    titleEn: 'Talib',
    titleBn: 'তালিব',
    iconName: 'menu_book',
  ),
  LmsLevelTier(
    index: 2,
    xpThreshold: 150,
    titleEn: 'Murid',
    titleBn: 'মুরিদ',
    iconName: 'auto_stories',
  ),
  LmsLevelTier(
    index: 3,
    xpThreshold: 350,
    titleEn: 'Alim',
    titleBn: 'আলিম',
    iconName: 'school',
  ),
  LmsLevelTier(
    index: 4,
    xpThreshold: 700,
    titleEn: 'Scholar (Alim Mutawassit)',
    titleBn: 'পণ্ডিত (আলিম মুতাওয়াস্সিত)',
    iconName: 'workspace_premium',
  ),
];

class LmsLevelInfo {
  const LmsLevelInfo({
    required this.tier,
    required this.xp,
    required this.progressToNext,
    required this.xpToNextLevel,
    required this.isMaxLevel,
  });

  final LmsLevelTier tier;
  final int xp;
  final double progressToNext;
  final int xpToNextLevel;
  final bool isMaxLevel;
}

LmsLevelInfo lmsLevelFromXp(int xp) {
  var current = kLmsLevelTiers.first;
  for (final tier in kLmsLevelTiers) {
    if (xp >= tier.xpThreshold) {
      current = tier;
    } else {
      break;
    }
  }

  final currentIndex = current.index;
  final isMax = currentIndex >= kLmsLevelTiers.length - 1;
  if (isMax) {
    return LmsLevelInfo(
      tier: current,
      xp: xp,
      progressToNext: 1,
      xpToNextLevel: 0,
      isMaxLevel: true,
    );
  }

  final next = kLmsLevelTiers[currentIndex + 1];
  final range = next.xpThreshold - current.xpThreshold;
  final earned = xp - current.xpThreshold;
  return LmsLevelInfo(
    tier: current,
    xp: xp,
    progressToNext: range > 0 ? (earned / range).clamp(0.0, 1.0) : 0,
    xpToNextLevel: next.xpThreshold - xp,
    isMaxLevel: false,
  );
}

String lmsLevelTitle(LmsLevelTier tier, AppLocalizations l10n) {
  return l10n.localeName.startsWith('bn') ? tier.titleBn : tier.titleEn;
}
