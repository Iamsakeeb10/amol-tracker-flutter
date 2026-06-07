import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';

class DhikrProgressArc extends StatelessWidget {
  const DhikrProgressArc({
    super.key,
    required this.count,
    required this.target,
    required this.justCompleted,
    required this.countLabel,
    required this.targetLabel,
  });

  final int count;
  final int target;
  final bool justCompleted;
  final String countLabel;
  final String targetLabel;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (count / target).clamp(0.0, 1.0);
    final arcColor = justCompleted ? AppColors.success : AppColors.gold;
    return SizedBox(
      width: 200.r,
      height: 200.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(200.r, 200.r),
            painter: _ArcPainter(
              progress: progress,
              color: arcColor,
              trackColor: AppColors.cardBorder,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: AppTextStyles.goldNumeric(context).copyWith(
                  fontSize: 42.sp,
                  color: arcColor,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                countLabel,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                targetLabel,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8.r;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.r
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.r
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
