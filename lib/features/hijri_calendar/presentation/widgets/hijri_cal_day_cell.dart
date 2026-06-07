import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';

class HijriCalDayCell extends StatelessWidget {
  const HijriCalDayCell({
    super.key,
    required this.hijriDay,
    required this.gregorianDay,
    required this.isToday,
    required this.hasEvent,
    required this.isEmpty,
    this.hijriDayLabel,
  });

  final int? hijriDay;
  final int? gregorianDay;
  final bool isToday;
  final bool hasEvent;
  final bool isEmpty;
  final String? hijriDayLabel;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.expand();

    final bg = isToday ? AppColors.goldCard : AppColors.cardDark;
    final border = isToday ? AppColors.goldBorder : AppColors.cardBorder;
    final hijriColor = isToday ? AppColors.gold : AppColors.textPrimary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        if (!size.isFinite || size <= 0) {
          return const SizedBox.shrink();
        }

        final hijriFont = (size * 0.34).clamp(9.0, 13.sp);
        final gregFont = (size * 0.24).clamp(7.0, 9.sp);
        final dotSize = (size * 0.1).clamp(3.0, 5.r);
        final dotRowH = (size * 0.2).clamp(5.0, 10.h);
        final gap = (size * 0.04).clamp(1.0, 2.h);
        final radius = (size * 0.18).clamp(6.0, 10.r);
        final borderW = isToday
            ? (size * 0.04).clamp(1.0, 1.5.r)
            : (size * 0.025).clamp(0.8, 1.r);

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border, width: borderW),
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      blurRadius: size * 0.08,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.06),
            child: hasEvent
                ? Column(
                    children: [
                      Expanded(
                        child: Center(child: _dateLabels(
                          context,
                          hijriFont: hijriFont,
                          gregFont: gregFont,
                          gap: gap,
                          hijriColor: hijriColor,
                        )),
                      ),
                      SizedBox(
                        height: dotRowH,
                        child: Center(
                          child: Container(
                            width: dotSize,
                            height: dotSize,
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: _dateLabels(
                      context,
                      hijriFont: hijriFont,
                      gregFont: gregFont,
                      gap: gap,
                      hijriColor: hijriColor,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _dateLabels(
    BuildContext context, {
    required double hijriFont,
    required double gregFont,
    required double gap,
    required Color hijriColor,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hijriDayLabel ?? '$hijriDay',
            maxLines: 1,
            style: AppTextStyles.bodyLarge(context).copyWith(
              fontSize: hijriFont,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
              color: hijriColor,
              height: 1.1,
            ),
          ),
          if (gregorianDay != null) ...[
            SizedBox(height: gap),
            Text(
              '$gregorianDay',
              maxLines: 1,
              style: AppTextStyles.bodySmall(context).copyWith(
                fontSize: gregFont,
                color: AppColors.textHint,
                height: 1.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
