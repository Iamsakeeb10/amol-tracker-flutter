import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/toggle_row.dart';
import '../../models/quran_reading_prefs.dart';
import '../../providers/quran_reading_prefs_provider.dart';
import '../../utils/quran_tap_targets.dart';

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
            SizedBox(height: 12.h),
            _FontSizeRow(
              icon: Icons.format_size_rounded,
              label: l10n.quranFontSize,
              scale: prefs.arabicFontScale,
              minScale: 0.8,
              maxScale: 1.6,
              onDecrease: notifier.decreaseFontScale,
              onIncrease: notifier.increaseFontScale,
            ),
            SizedBox(height: 8.h),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.gold,
                inactiveTrackColor: AppColors.gold.withValues(alpha: 0.2),
                thumbColor: AppColors.gold,
                overlayColor: AppColors.gold.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: prefs.arabicFontScale,
                min: 0.8,
                max: 1.6,
                divisions: 10,
                label: '${(prefs.arabicFontScale * 100).round()}%',
                onChanged: notifier.setArabicFontScale,
              ),
            ),
            SizedBox(height: 8.h),
            _FontSizeRow(
              icon: Icons.subtitles_outlined,
              label: l10n.quranTranslationFontSize,
              scale: prefs.translationFontScale,
              minScale: 0.8,
              maxScale: 1.4,
              onDecrease: notifier.decreaseTranslationFontScale,
              onIncrease: notifier.increaseTranslationFontScale,
            ),
          ],
        ),
      ),
    );
  }
}

class _FontSizeRow extends StatelessWidget {
  const _FontSizeRow({
    required this.icon,
    required this.label,
    required this.scale,
    required this.minScale,
    required this.maxScale,
    required this.onDecrease,
    required this.onIncrease,
  });

  final IconData icon;
  final String label;
  final double scale;
  final double minScale;
  final double maxScale;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34.r,
          height: 34.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.cardBorder,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 16.r, color: AppColors.gold),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge(context).copyWith(fontSize: 14.sp),
          ),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context)!.duaReaderTextSizeDecrease,
          style: QuranTapTargets.iconButtonStyle(),
          icon: Icon(
            Icons.remove_rounded,
            size: 22.r,
            color: scale > minScale ? AppColors.textPrimary : AppColors.textMuted,
          ),
          onPressed: scale > minScale ? onDecrease : null,
        ),
        Text(
          '${(scale * 100).round()}%',
          style: AppTextStyles.bodyLarge(context).copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
            color: AppColors.gold,
          ),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context)!.duaReaderTextSizeIncrease,
          style: QuranTapTargets.iconButtonStyle(),
          icon: Icon(
            Icons.add_rounded,
            size: 22.r,
            color: scale < maxScale ? AppColors.textPrimary : AppColors.textMuted,
          ),
          onPressed: scale < maxScale ? onIncrease : null,
        ),
      ],
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
