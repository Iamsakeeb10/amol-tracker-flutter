import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../mock/mock_data.dart';

class CalendarDayCell extends StatelessWidget {
  final MockDay day;
  final VoidCallback? onTap;

  const CalendarDayCell({super.key, required this.day, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color textColor = AppColors.textPrimary;

    switch (day.state) {
      case DayCompletion.full:
        bg = AppColors.gold;
        border = AppColors.goldLight;
        textColor = AppColors.emeraldDeep;
        break;
      case DayCompletion.partial:
        bg = AppColors.warningLight;
        border = AppColors.warning.withValues(alpha: 0.4);
        textColor = AppColors.goldPale;
        break;
      case DayCompletion.miss:
        bg = AppColors.dangerLight;
        border = AppColors.danger.withValues(alpha: 0.4);
        textColor = AppColors.danger;
        break;
      case DayCompletion.today:
        bg = AppColors.cardDark;
        border = AppColors.gold;
        break;
      case DayCompletion.future:
        bg = Colors.transparent;
        border = AppColors.cardBorder;
        textColor = AppColors.textHint;
        break;
    }

    final borderW = day.state == DayCompletion.today ? 1.5.r : 1.r;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: border,
              width: borderW,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontSize: 12.sp,
              fontWeight: day.state == DayCompletion.full
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
