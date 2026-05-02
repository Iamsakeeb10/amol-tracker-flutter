import 'package:flutter/material.dart';

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
    final r = borderRadius ?? BorderRadius.circular(99);
    return ClipRRect(
      borderRadius: r,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: trackColor ?? AppColors.cardBorder),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (color ?? AppColors.gold),
                      (color ?? AppColors.goldLight),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
