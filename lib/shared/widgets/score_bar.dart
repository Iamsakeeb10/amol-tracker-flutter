import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';

class ScoreBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;
  final BorderRadius? borderRadius;

  const ScoreBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
    this.trackColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? BorderRadius.circular(99.r);
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: r,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth = constraints.maxWidth * clamped;
          return SizedBox(
            height: height.h,
            child: Stack(
              children: [
                Container(color: trackColor ?? AppColors.cardBorder),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: fillWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (color ?? AppColors.gold),
                        (color ?? AppColors.goldLight),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
