import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/toggle_row.dart';
import '../../models/quran_reading_prefs.dart';
import '../../providers/quran_reading_prefs_provider.dart';

Future<void> showTranslationPanel(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const TranslationPanel(),
  );
}

class TranslationPanel extends ConsumerWidget {
  const TranslationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(quranReadingPrefsProvider);
    final notifier = ref.read(quranReadingPrefsProvider.notifier);

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
              l10n.quranTranslation,
              style: AppTextStyles.headlineMedium(context),
            ),
            SizedBox(height: 16.h),
            ToggleRow(
              icon: Icons.translate_rounded,
              title: l10n.quranTranslation,
              value: prefs.showTranslation,
              onChanged: notifier.setShowTranslation,
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.quranSelectTranslator,
              style: AppTextStyles.label(context).copyWith(color: AppColors.gold),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _TranslatorChip(
                  label: l10n.quranTranslatorKhan,
                  selected: prefs.translator == QuranTranslator.khan,
                  onSelected: () => notifier.setTranslator(QuranTranslator.khan),
                ),
                _TranslatorChip(
                  label: l10n.quranTranslatorSahih,
                  selected: prefs.translator == QuranTranslator.sahih,
                  onSelected: () => notifier.setTranslator(QuranTranslator.sahih),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
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
                    Icons.format_size_rounded,
                    size: 16.r,
                    color: AppColors.gold,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    l10n.quranFontSize,
                    style: AppTextStyles.bodyLarge(context).copyWith(fontSize: 14.sp),
                  ),
                ),
                IconButton(
                  tooltip: l10n.duaReaderTextSizeDecrease,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.all(8.r),
                  constraints: BoxConstraints(minWidth: 36.r, minHeight: 36.r),
                  icon: Icon(
                    Icons.remove_rounded,
                    size: 22.r,
                    color: prefs.arabicFontScale > 0.8
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                  onPressed:
                      prefs.arabicFontScale > 0.8 ? notifier.decreaseFontScale : null,
                ),
                Text(
                  '${(prefs.arabicFontScale * 100).round()}%',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                    color: AppColors.gold,
                  ),
                ),
                IconButton(
                  tooltip: l10n.duaReaderTextSizeIncrease,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.all(8.r),
                  constraints: BoxConstraints(minWidth: 36.r, minHeight: 36.r),
                  icon: Icon(
                    Icons.add_rounded,
                    size: 22.r,
                    color: prefs.arabicFontScale < 1.6
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                  onPressed:
                      prefs.arabicFontScale < 1.6 ? notifier.increaseFontScale : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TranslatorChip extends StatelessWidget {
  const _TranslatorChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(AppRadius.md.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.goldCard,
          borderRadius: BorderRadius.circular(AppRadius.md.r),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.goldBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: selected ? AppColors.emeraldDeep : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
