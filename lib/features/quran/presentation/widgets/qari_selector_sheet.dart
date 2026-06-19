import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../constants/quran_constants.dart';
import '../../providers/quran_audio_provider.dart';
import '../../providers/quran_reading_prefs_provider.dart';

class QariSelectorSheet extends ConsumerWidget {
  const QariSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(quranReadingPrefsProvider);
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.quranSelectQari,
            style: AppTextStyles.headlineMedium(context),
          ),
          SizedBox(height: 12.h),
          ...QuranConstants.qaris.map((qari) {
            final selected = prefs.qari == qari.id;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                isBn ? qari.nameBn : qari.nameEn,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: selected ? AppColors.gold : AppColors.textPrimary,
                ),
              ),
              trailing: selected
                  ? Icon(Icons.check_circle, color: AppColors.gold, size: 20.r)
                  : null,
              onTap: () async {
                await ref.read(quranAudioProvider.notifier).setQari(qari.id);
                if (context.mounted) Navigator.of(context).pop();
              },
            );
          }),
        ],
      ),
    );
  }
}

void showQariSelectorSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const QariSelectorSheet(),
  );
}
