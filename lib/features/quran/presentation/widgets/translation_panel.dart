import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/toggle_row.dart';
import '../../models/quran_reading_prefs.dart';
import '../../providers/quran_reading_prefs_provider.dart';

class TranslationPanel extends ConsumerWidget {
  const TranslationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(quranReadingPrefsProvider);
    final notifier = ref.read(quranReadingPrefsProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl.r)),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.quranTranslation,
            style: AppTextStyles.headlineMedium(context),
          ),
          SizedBox(height: 12.h),
          ToggleRow(
            icon: Icons.translate_outlined,
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
              ChoiceChip(
                label: Text(l10n.quranTranslatorKhan),
                selected: prefs.translator == QuranTranslator.khan,
                onSelected: (_) => notifier.setTranslator(QuranTranslator.khan),
              ),
              ChoiceChip(
                label: Text(l10n.quranTranslatorSahih),
                selected: prefs.translator == QuranTranslator.sahih,
                onSelected: (_) => notifier.setTranslator(QuranTranslator.sahih),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Text(l10n.quranFontSize, style: AppTextStyles.bodyMedium(context)),
              const Spacer(),
              IconButton(
                onPressed: notifier.decreaseFontScale,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '${(prefs.arabicFontScale * 100).round()}%',
                style: AppTextStyles.bodySmall(context),
              ),
              IconButton(
                onPressed: notifier.increaseFontScale,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void showTranslationPanel(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const TranslationPanel(),
  );
}
