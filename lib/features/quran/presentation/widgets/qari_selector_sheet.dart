import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../constants/quran_constants.dart';
import '../../providers/quran_audio_provider.dart';
import '../../providers/quran_reading_prefs_provider.dart';

Future<void> showQariSelectorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const QariSelectorSheet(),
  );
}

class QariSelectorSheet extends ConsumerWidget {
  const QariSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(quranReadingPrefsProvider);
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 16.h),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.emeraldMid,
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(99.r),
                ),
              ),
            ),
            Text(
              l10n.quranSelectQari,
              style: AppTextStyles.headlineMedium(context),
            ),
            SizedBox(height: 12.h),
            ...QuranConstants.qaris.map((qari) {
              final selected = prefs.qari == qari.id;
              return InkWell(
                onTap: () async {
                  await ref.read(quranAudioProvider.notifier).setQari(qari.id);
                  if (context.mounted) Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(AppRadius.md.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
                  child: Row(
                    children: [
                      Container(
                        width: 34.r,
                        height: 34.r,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.cardBorder,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.mic_rounded,
                          size: 16.r,
                          color: selected ? AppColors.gold : AppColors.textMuted,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          isBn ? qari.nameBn : qari.nameEn,
                          style: AppTextStyles.bodyLarge(context).copyWith(
                            fontSize: 14.sp,
                            color: selected ? AppColors.gold : AppColors.textPrimary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle, color: AppColors.gold, size: 20.r),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
