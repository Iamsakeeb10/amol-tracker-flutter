import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/dhikr_provider.dart';
import '../../../../shared/widgets/card_container.dart';

Future<void> showCustomDhikrDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => const CustomDhikrDialog(),
  );
}

class CustomDhikrDialog extends ConsumerStatefulWidget {
  const CustomDhikrDialog({super.key});

  @override
  ConsumerState<CustomDhikrDialog> createState() => _CustomDhikrDialogState();
}

class _CustomDhikrDialogState extends ConsumerState<CustomDhikrDialog> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController(text: '33');
  final _nameFocus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final target = int.tryParse(_targetController.text.trim()) ?? 0;
    final error = await ref.read(dhikrProvider.notifier).addCustomPreset(
          name: _nameController.text,
          target: target,
        );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _error = switch (error) {
        'empty_name' => l10n.dhikrNameRequired,
        'invalid_target' => l10n.dhikrTargetInvalid,
        'duplicate_name' => l10n.dhikrDuplicateName,
        _ => l10n.dhikrTargetInvalid,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: bottomInset),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: SingleChildScrollView(
          child: CardContainer(
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 14.h),
            borderColor: AppColors.goldBorder,
            color: AppColors.emeraldMid,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dhikrAddCustom,
                  style: AppTextStyles.headlineMedium(context),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  style: AppTextStyles.bodyLarge(context),
                  decoration: InputDecoration(
                    labelText: l10n.dhikrCustomName,
                    labelStyle: AppTextStyles.bodySmall(context),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: AppTextStyles.bodyLarge(context),
                  decoration: InputDecoration(
                    labelText: l10n.dhikrCustomTarget,
                    labelStyle: AppTextStyles.bodySmall(context),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    _error!,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.danger,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.emeraldDeep,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          l10n.dhikrAdd,
                          style: AppTextStyles.button(context).copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
