import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/dua_reader_settings_provider.dart';

String duaTextSizeLabel(AppLocalizations l10n, DuaTextSize size) {
  switch (size) {
    case DuaTextSize.normal:
      return l10n.duaReaderTextSizeNormal;
    case DuaTextSize.medium:
      return l10n.duaReaderTextSizeMedium;
    case DuaTextSize.large:
      return l10n.duaReaderTextSizeLarge;
  }
}

Future<void> showDuaReaderFontControl(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black26,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, _, _) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(top: 4.h, right: 52.w),
            child: const _DuaReaderFontControlPanel(),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          alignment: Alignment.topRight,
          child: child,
        ),
      );
    },
  );
}

class DuaReaderFontControlButton extends ConsumerWidget {
  const DuaReaderFontControlButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      tooltip: l10n.duaReaderTextSize,
      icon: Icon(Icons.format_size_rounded, size: 20.r),
      onPressed: () => showDuaReaderFontControl(context),
    );
  }
}

class _DuaReaderFontControlPanel extends ConsumerWidget {
  const _DuaReaderFontControlPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(duaReaderSettingsProvider);
    final notifier = ref.read(duaReaderSettingsProvider.notifier);
    final canDecrease = settings.textSize.index > 0;
    final canIncrease =
        settings.textSize.index < DuaTextSize.values.length - 1;

    return Material(
      color: AppColors.emeraldMid,
      elevation: 6,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ControlButton(
              icon: Icons.remove_rounded,
              tooltip: l10n.duaReaderTextSizeDecrease,
              onPressed: canDecrease ? notifier.decreaseTextSize : null,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.duaReaderTextSize,
                    style: AppTextStyles.label(context).copyWith(
                      color: AppColors.textMuted,
                      fontSize: 9.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    duaTextSizeLabel(l10n, settings.textSize),
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
            _ControlButton(
              icon: Icons.add_rounded,
              tooltip: l10n.duaReaderTextSizeIncrease,
              onPressed: canIncrease ? notifier.increaseTextSize : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.all(8.r),
      constraints: BoxConstraints(minWidth: 36.r, minHeight: 36.r),
      icon: Icon(
        icon,
        size: 22.r,
        color: onPressed != null ? AppColors.textPrimary : AppColors.textMuted,
      ),
      onPressed: onPressed,
    );
  }
}
