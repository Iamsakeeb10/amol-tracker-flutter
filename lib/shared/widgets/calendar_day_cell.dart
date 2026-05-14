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
    FontWeight fontWeight = FontWeight.w400;

    switch (day.state) {
      case DayCompletion.full:
        // ✅ Alhamdulillah — gold, celebrated
        bg = AppColors.gold;
        border = AppColors.goldLight;
        textColor = AppColors.emeraldDeep;
        fontWeight = FontWeight.w600;

      case DayCompletion.partial:
        // 🌙 Ma sha Allah — warm amber, acknowledged
        bg = AppColors.warningLight;
        border = AppColors.warning.withValues(alpha: 0.4);
        textColor = AppColors.goldPale;
        fontWeight = FontWeight.w500;

      case DayCompletion.light:
        // 🟠 Keep Going — faint amber, not shamed
        bg = AppColors.warning.withValues(alpha: 0.08);
        border = AppColors.warning.withValues(alpha: 0.25);
        textColor = AppColors.warning.withValues(alpha: 0.7);

      case DayCompletion.minimal:
        // 💧 A Start — very subtle, neutral-positive
        bg = AppColors.cardDark.withValues(alpha: 0.6);
        border = AppColors.textMuted.withValues(alpha: 0.3);
        textColor = AppColors.textMuted;

      case DayCompletion.miss:
        // score == 0 but log exists — neutral grey, no red shame
        bg = AppColors.cardDark;
        border = AppColors.cardBorder;
        textColor = AppColors.textMuted;

      case DayCompletion.noData:
        // No log at all — completely blank, non-judgmental
        bg = Colors.transparent;
        border = AppColors.cardBorder.withValues(alpha: 0.4);
        textColor = AppColors.textHint;

      case DayCompletion.today:
        bg = AppColors.success.withValues(alpha: 0.15);
        border = AppColors.success;
        textColor = AppColors.success;
        fontWeight = FontWeight.w600;

      case DayCompletion.future:
        bg = Colors.transparent;
        border = AppColors.cardBorder;
        textColor = AppColors.textHint;

      case DayCompletion.preAccount:
        bg = AppColors.cardDark.withValues(alpha: 0.3);
        border = AppColors.cardBorder.withValues(alpha: 0.3);
        textColor = AppColors.textMuted.withValues(alpha: 0.4);
    }

    final borderW = day.state == DayCompletion.today ? 1.5.r : 1.r;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Main cell ──────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: border, width: borderW),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12.sp,
                      fontWeight: fontWeight,
                    ),
                  ),
                  if (_showDot(day.state))
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Container(
                        width: 4.r,
                        height: 4.r,
                        decoration: BoxDecoration(
                          color: _dotColor(day.state),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── "আজ" badge — only for today ────────────────────
            if (day.state == DayCompletion.today)
              Positioned(
                top: -4.r,
                right: -4.r,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    'আজ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show a small dot indicator for logged days so users
  /// get positive visual feedback even on low-score days.
  bool _showDot(DayCompletion state) {
    switch (state) {
      case DayCompletion.full:
      case DayCompletion.partial:
      case DayCompletion.light:
      case DayCompletion.minimal:
      case DayCompletion.miss:
        return true;
      default:
        return false;
    }
  }

  Color _dotColor(DayCompletion state) {
    switch (state) {
      case DayCompletion.full:
        return AppColors.emeraldDeep;
      case DayCompletion.partial:
        return AppColors.warning;
      case DayCompletion.light:
        return AppColors.warning.withValues(alpha: 0.5);
      case DayCompletion.minimal:
        return AppColors.textMuted;
      case DayCompletion.miss:
        return AppColors.textMuted.withValues(alpha: 0.4);
      default:
        return Colors.transparent;
    }
  }
}
