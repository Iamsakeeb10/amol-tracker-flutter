import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../constants/quran_text_styles.dart';
import '../../models/quran_ayah.dart';
import '../../providers/quran_reading_prefs_provider.dart';

class AyahCardWidget extends ConsumerWidget {
  const AyahCardWidget({
    super.key,
    required this.ayah,
    required this.highlighted,
    this.onTap,
  });

  final QuranAyah ayah;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(quranReadingPrefsProvider);
    final baseSize = 22.sp * prefs.arabicFontScale;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg.r),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.fromLTRB(
          highlighted ? 14.w : 16.w,
          14.h,
          16.w,
          14.h,
        ),
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.emeraldMid.withValues(alpha: 0.85)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
          border: Border.all(
            color: highlighted ? AppColors.gold : AppColors.cardBorder,
            width: highlighted ? 1.5.r : 1.r,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.emeraldDeep,
                  borderRadius: BorderRadius.circular(AppRadius.sm.r),
                ),
                child: Text(
                  '${ayah.ayah}',
                  style: AppTextStyles.label(context).copyWith(
                    color: AppColors.gold,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              ayah.textAr,
              style: QuranTextStyles.arabic(
                fontSize: baseSize,
                height: 2.0,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            if (prefs.showTranslation &&
                (ayah.translation?.trim().isNotEmpty ?? false)) ...[
              SizedBox(height: 12.h),
              Text(
                ayah.translation!,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
