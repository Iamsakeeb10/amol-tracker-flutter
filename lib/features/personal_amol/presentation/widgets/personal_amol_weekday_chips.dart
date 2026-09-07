import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';

/// Renders the weekday picker for weekday personal amols as two-line chips:
/// English short name on top and Bangla name below (always, for visual parity
/// with the create-sheet design).
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

  /// Bangla abbreviations shown on the chip sub-label regardless of locale.
  static const Map<int, String> _kBanglaNames = <int, String>{
    1: 'শনি',
    2: 'রবি',
    3: 'সোম',
    4: 'মঙ্গল',
    5: 'বুধ',
    6: 'বৃহস্পতি',
    7: 'শুক্র',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (dayIndex, en) in _kOrderedDays)
          _chip(
            context,
            en: en,
            bn: _kBanglaNames[dayIndex] ?? '',
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
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: 44.w,
        // Minimum 44h effective tap target; symmetric padding contributes
        // to the touchable area on top and bottom of the chip text.
        padding: EdgeInsets.symmetric(vertical: 10.h),
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
}
