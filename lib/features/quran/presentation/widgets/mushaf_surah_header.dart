import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../constants/quran_text_styles.dart';
import '../../models/quran_surah.dart';

/// Standard bismillah text for surah headers (not shown for surahs 1 and 9).
const mushafBismillah =
    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

class MushafSurahHeader extends StatelessWidget {
  const MushafSurahHeader({
    super.key,
    required this.surah,
    required this.showBismillah,
  });

  final QuranSurah surah;
  final bool showBismillah;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.emeraldMid.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.md.r),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                Text(
                  surah.nameAr,
                  style: QuranTextStyles.arabic(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: AppColors.gold,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 4.h),
                Text(
                  surah.displayName(languageCode),
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm.r),
                      ),
                      child: Text(
                        surah.isMeccan ? l10n.quranMeccan : l10n.quranMedinan,
                        style: AppTextStyles.pill(context).copyWith(
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      l10n.quranAyahs(surah.ayahCount),
                      style: AppTextStyles.bodySmall(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showBismillah) ...[
            SizedBox(height: 10.h),
            Text(
              mushafBismillah,
              style: QuranTextStyles.arabic(
                fontSize: 18.sp,
                height: 2.0,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ],
        ],
      ),
    );
  }
}
