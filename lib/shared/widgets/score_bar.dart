import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../../providers/device_tier_provider.dart';

class ScoreBar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final r = borderRadius ?? BorderRadius.circular(99.r);
    final clamped = value.clamp(0.0, 1.0);
    final reduceMotion = ref.watch(reduceMotionProvider);
    final fillDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [
          (color ?? AppColors.gold),
          (color ?? AppColors.goldLight),
        ],
      ),
    );

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
                if (reduceMotion)
                  Container(width: fillWidth, decoration: fillDecoration)
                else
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: fillWidth,
                    decoration: fillDecoration,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
