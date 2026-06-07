import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/asma_ul_husna.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';

class HusnaProgressHeader extends ConsumerWidget {
  const HusnaProgressHeader({
    super.key,
    required this.learnedCount,
    required this.learnedPercent,
    required this.canStartQuiz,
    required this.onStartQuiz,
  });

  final int learnedCount;
  final int learnedPercent;
  final bool canStartQuiz;
  final VoidCallback onStartQuiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final progress = learnedCount / kHusnaTotalCount;

    return CardContainer(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 72.r,
                height: 72.r,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(72.r, 72.r),
                      painter: _HusnaArcPainter(
                        progress: progress.clamp(0.0, 1.0),
                        color: AppColors.gold,
                        trackColor: AppColors.cardBorder,
                      ),
                    ),
                    Text(
                      '$learnedPercent%',
                      style: AppTextStyles.goldNumeric(context).copyWith(
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.husnaSubtitle,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      l10n.husnaLearnedCount(learnedCount),
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ScoreBar(value: progress, height: 5),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canStartQuiz ? onStartQuiz : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.emeraldDeep,
                disabledBackgroundColor: AppColors.cardBorder,
                disabledForegroundColor: AppColors.textMuted,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              icon: Icon(Icons.quiz_outlined, size: 18.r),
              label: Text(
                canStartQuiz ? l10n.husnaStartQuiz : l10n.husnaNoNamesLearned,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      canStartQuiz ? AppColors.emeraldDeep : AppColors.textMuted,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HusnaArcPainter extends CustomPainter {
  _HusnaArcPainter({
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
    final radius = size.width / 2 - 4;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HusnaArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
