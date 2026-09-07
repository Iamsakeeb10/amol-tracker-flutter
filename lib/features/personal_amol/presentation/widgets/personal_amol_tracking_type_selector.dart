import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/personal_amol_model.dart';

/// Segmented control for a personal amol's tracking type (toggle | count),
/// matching the gold sliding-thumb look of `personal_amol_create_sheet_v3.html`.
class PersonalAmolTrackingTypeSelector extends ConsumerWidget {
  const PersonalAmolTrackingTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PersonalAmolType value;
  final ValueChanged<PersonalAmolType> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        _segment(
          context,
          label: l10n.personalAmolTypeToggle,
          index: 0,
          selected: value == PersonalAmolType.toggle,
          onTap: () => onChanged(PersonalAmolType.toggle),
        ),
        SizedBox(width: 8.w),
        _segment(
          context,
          label: l10n.personalAmolTypeCount,
          index: 1,
          selected: value == PersonalAmolType.count,
          onTap: () => onChanged(PersonalAmolType.count),
        ),
      ],
    );
  }

  Widget _segment(
    BuildContext context, {
    required String label,
    required int index,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isLeft = index == 0;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 46.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : AppColors.cardDark,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isLeft ? 12.r : 6.r),
              bottomLeft: Radius.circular(isLeft ? 12.r : 6.r),
              topRight: Radius.circular(!isLeft ? 12.r : 6.r),
              bottomRight: Radius.circular(!isLeft ? 12.r : 6.r),
            ),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: selected ? AppColors.emeraldDeep : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}