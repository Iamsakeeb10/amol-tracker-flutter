import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

class CelebrationBurstPainter extends CustomPainter {
  CelebrationBurstPainter({required this.progress});

  final double progress;

  static final _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  static final _rayPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2;
  static final _dotPaint = Paint()..style = PaintingStyle.fill;

  static const _burstDots = <(double, double, bool)>[
    (0.0, -1.0, false),
    (0.71, -0.71, true),
    (1.0, 0.0, false),
    (0.71, 0.71, true),
    (0.0, 1.0, false),
    (-0.71, 0.71, true),
    (-1.0, 0.0, false),
    (-0.71, -0.71, true),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    final maxRadius = size.shortestSide * 0.48;

    _ringPaint.color = AppColors.goldPale.withValues(
      alpha: (1 - progress) * 0.55,
    );
    canvas.drawCircle(center, maxRadius * (0.35 + progress * 0.65), _ringPaint);

    const rays = 18;
    final innerR = maxRadius * 0.16;
    final fadeAlpha = (1 - progress) * 0.7;

    for (var i = 0; i < rays; i++) {
      final angle = (math.pi * 2 * i) / rays;
      final length = maxRadius * (0.25 + 0.65 * progress);
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      final start = Offset(center.dx + cosA * innerR, center.dy + sinA * innerR);
      final end = Offset(center.dx + cosA * length, center.dy + sinA * length);
      _rayPaint.color = (i.isEven ? AppColors.goldLight : AppColors.cream)
          .withValues(alpha: fadeAlpha);
      canvas.drawLine(start, end, _rayPaint);
    }

    final spread = maxRadius * (0.35 + progress * 0.85);
    final dotAlpha = (1 - progress).clamp(0.0, 1.0);
    final dotRadius = 2.2 + (1 - progress) * 1.6;

    for (var i = 0; i < _burstDots.length; i++) {
      final (cosA, sinA, isPale) = _burstDots[i];
      final p = Offset(center.dx + cosA * spread, center.dy + sinA * spread);
      _dotPaint.color = (isPale ? AppColors.goldPale : AppColors.goldLight)
          .withValues(alpha: dotAlpha);
      canvas.drawCircle(p, dotRadius, _dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CelebrationBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
