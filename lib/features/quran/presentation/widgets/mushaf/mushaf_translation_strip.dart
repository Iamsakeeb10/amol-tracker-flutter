import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../models/quran_reading_prefs.dart';
import '../../../providers/quran_mushaf_provider.dart';
import '../../../providers/quran_reading_prefs_provider.dart';

/// Scrollable translation list for the ayahs on the current mushaf page.
class MushafTranslationStrip extends ConsumerWidget {
  const MushafTranslationStrip({
    super.key,
    required this.pageNumber,
  });

  final int pageNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(quranReadingPrefsProvider);
    if (!prefs.showTranslation) {
      return const SizedBox.shrink();
    }

    final ayahsAsync = ref.watch(
      quranMushafPageAyahsProvider(
        MushafPageAyahsQuery(
          page: pageNumber,
          translator: prefs.translator.dbKey,
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.emeraldDeep.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: ayahsAsync.when(
          loading: () => SizedBox(
            height: 48.h,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (ayahs) {
            final entries = ayahs
                .where((a) => a.translation?.trim().isNotEmpty ?? false)
                .toList(growable: false);
            if (entries.isEmpty) return const SizedBox.shrink();

            return SizedBox(
              height: 132.h,
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
                itemCount: entries.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final ayah = entries[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 2.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '${ayah.surah}:${ayah.ayah}',
                          style: AppTextStyles.label(context).copyWith(
                            color: AppColors.gold,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          ayah.translation!,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
