import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// Renders the weekday picker for "নির্দিষ্ট দিন" personal amols as two-line
/// chips: the English short name on top and the full Bangla name below.
///
/// Day indices are 1-based in the model (1 = Saturday ... 7 = Friday), but the
/// chips display in Sunday-first order to match the design reference.
class PersonalAmolWeekdayChips extends ConsumerWidget {
  const PersonalAmolWeekdayChips({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  static const List<(int dayIndex, String en)> _kOrderedDays = <(int, String)>[
    (2, 'Sun'),
    (3, 'Mon'),
    (4, 'Tue'),
    (5, 'Wed'),
    (6, 'Thu'),
    (7, 'Fri'),
    (1, 'Sat'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (dayIndex, en) in _kOrderedDays)
          _chip(
            context,
            en: en,
            bn: _banglaName(l10n, dayIndex),
            selected: selected.contains(dayIndex),
            onTap: () => onToggle(dayIndex),
          ),
      ],
    );
  }

  Widget _chip(
    BuildContext context, {
    required String en,
    required String bn,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: 44.w,
        padding: EdgeInsets.symmetric(vertical: 7.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.cardDark,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.cardBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              en,
              style: AppTextStyles.label(context).copyWith(
                fontSize: 10.sp,
                color: selected
                    ? AppColors.emeraldDeep
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              bn,
              style: AppTextStyles.label(context).copyWith(
                fontSize: 9.sp,
                color: selected
                    ? AppColors.emeraldDeep
                    : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _banglaName(AppLocalizations l10n, int dayIndex) {
    switch (dayIndex) {
      case 1:
        return l10n.personalAmolWeekdaySat;
      case 2:
        return l10n.personalAmolWeekdaySun;
      case 3:
        return l10n.personalAmolWeekdayMon;
      case 4:
        return l10n.personalAmolWeekdayTue;
      case 5:
        return l10n.personalAmolWeekdayWed;
      case 6:
        return l10n.personalAmolWeekdayThu;
      case 7:
        return l10n.personalAmolWeekdayFri;
    }
    return '';
  }
}