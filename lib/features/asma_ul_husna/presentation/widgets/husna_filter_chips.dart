import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/asma_ul_husna_provider.dart';

class HusnaFilterChips extends StatelessWidget {
  const HusnaFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final HusnaFilterMode selected;
  final ValueChanged<HusnaFilterMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: l10n.husnaFilterAll,
            selected: selected == HusnaFilterMode.all,
            onTap: () => onChanged(HusnaFilterMode.all),
          ),
          SizedBox(width: 8.w),
          _Chip(
            label: l10n.husnaFilterLearned,
            selected: selected == HusnaFilterMode.learned,
            onTap: () => onChanged(HusnaFilterMode.learned),
          ),
          SizedBox(width: 8.w),
          _Chip(
            label: l10n.husnaFilterNotLearned,
            selected: selected == HusnaFilterMode.notLearned,
            onTap: () => onChanged(HusnaFilterMode.notLearned),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: AppTextStyles.bodySmall(context).copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.emeraldDeep : AppColors.textSecondary,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.cardDark,
      side: BorderSide(
        color: selected ? AppColors.goldBorder : AppColors.cardBorder,
      ),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      visualDensity: VisualDensity.compact,
    );
  }
}
