import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/dhikr_model.dart';
import '../../../../providers/dhikr_provider.dart';
import 'custom_dhikr_dialog.dart';

Future<void> showDhikrSelectorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DhikrSelectorSheet(parentContext: context),
  );
}

class DhikrSelectorSheet extends ConsumerWidget {
  const DhikrSelectorSheet({super.key, required this.parentContext});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(dhikrProvider);
    final notifier = ref.read(dhikrProvider.notifier);
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
          children: [
            Container(
              width: 36.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
            Text(
              l10n.dhikrSelectDhikr,
              style: AppTextStyles.headlineMedium(context),
            ),
            SizedBox(height: 12.h),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: state.allPresets.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final preset = state.allPresets[index];
                  final selected = preset.id == state.selectedPreset.id;
                  return _PresetTile(
                    preset: preset,
                    selected: selected,
                    onTap: () async {
                      await notifier.selectPreset(preset);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    onDelete: preset.isCustom
                        ? () async {
                            await notifier.deleteCustomPreset(preset.id);
                          }
                        : null,
                  );
                },
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  showCustomDhikrDialog(parentContext);
                },
                icon: Icon(Icons.add_rounded, size: 16.r, color: AppColors.gold),
                label: Text(
                  l10n.dhikrAdd,
                  style: AppTextStyles.button(context).copyWith(
                    color: AppColors.gold,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.goldBorder),
                  backgroundColor: AppColors.goldCard,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
    this.onDelete,
  });

  final DhikrPreset preset;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.gold : AppColors.textMuted,
              size: 20.r,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.displayName(l10n),
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  if (preset.arabicName != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      preset.arabicName!,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                  SizedBox(height: 2.h),
                  Text(
                    l10n.dhikrTarget(preset.target),
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
              ),
          ],
        ),
      ),
    );
  }
}
