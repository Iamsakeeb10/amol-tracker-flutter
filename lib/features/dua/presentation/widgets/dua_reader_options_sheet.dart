import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/toggle_row.dart';
import '../../providers/dua_reader_settings_provider.dart';

Future<void> showDuaReaderOptionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const DuaReaderOptionsSheet(),
  );
}

class DuaReaderOptionsSheet extends ConsumerWidget {
  const DuaReaderOptionsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(duaReaderSettingsProvider);
    final notifier = ref.read(duaReaderSettingsProvider.notifier);

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
              l10n.duaReaderOptions,
              style: AppTextStyles.headlineMedium(context),
            ),
            SizedBox(height: 16.h),
            ToggleRow(
              icon: Icons.info_outline_rounded,
              title: l10n.duaReaderShowIntroduction,
              value: settings.showIntroduction,
              onChanged: notifier.setShowIntroduction,
            ),
            ToggleRow(
              icon: Icons.spellcheck_outlined,
              title: l10n.duaReaderShowTransliteration,
              value: settings.showTransliteration,
              onChanged: notifier.setShowTransliteration,
            ),
            ToggleRow(
              icon: Icons.translate_rounded,
              title: l10n.duaReaderShowTranslation,
              value: settings.showTranslation,
              onChanged: notifier.setShowTranslation,
            ),
            ToggleRow(
              icon: Icons.bookmark_outline_rounded,
              title: l10n.duaReaderShowReference,
              value: settings.showReference,
              onChanged: notifier.setShowReference,
            ),
          ],
        ),
      ),
    );
  }
}
