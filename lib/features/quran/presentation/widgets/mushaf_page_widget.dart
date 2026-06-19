import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../constants/quran_text_styles.dart';
import '../../models/quran_ayah.dart';
import '../../models/quran_surah.dart';
import '../../providers/quran_reading_prefs_provider.dart';

class MushafPageWidget extends ConsumerWidget {
  const MushafPageWidget({
    super.key,
    required this.ayahs,
    required this.surah,
    required this.highlightedSurah,
    required this.highlightedAyah,
    this.onAyahTap,
  });

  final List<QuranAyah> ayahs;
  final QuranSurah? surah;
  final int highlightedSurah;
  final int highlightedAyah;
  final ValueChanged<QuranAyah>? onAyahTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(quranReadingPrefsProvider);
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final baseSize = 24.sp * prefs.arabicFontScale;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 120.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (surah != null &&
              ayahs.isNotEmpty &&
              ayahs.first.ayah == 1) ...[
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(AppRadius.lg.r),
                border: Border.all(color: AppColors.goldBorder),
              ),
              child: Column(
                children: [
                  Text(
                    surah!.nameAr,
                    style: QuranTextStyles.arabic(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    languageCode == 'bn'
                        ? surah!.displayName(languageCode)
                        : '${surah!.nameTransliteration} • ${surah!.nameEn}',
                    style: AppTextStyles.bodySmall(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    surah!.isMeccan ? l10n.quranMeccan : l10n.quranMedinan,
                    style: AppTextStyles.pill(context),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],
          ...ayahs.map((ayah) {
            final highlighted =
                ayah.surah == highlightedSurah && ayah.ayah == highlightedAyah;
            return GestureDetector(
              onTap: () => onAyahTap?.call(ayah),
              child: Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                decoration: highlighted
                    ? BoxDecoration(
                        color: AppColors.emeraldMid.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(AppRadius.md.r),
                      )
                    : null,
                child: Text(
                  ayah.textAr,
                  style: QuranTextStyles.arabic(
                    fontSize: baseSize,
                    height: 2.1,
                    backgroundColor: highlighted
                        ? AppColors.gold.withValues(alpha: 0.12)
                        : null,
                  ),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
