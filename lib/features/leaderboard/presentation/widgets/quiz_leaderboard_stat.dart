import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class QuizLeaderboardStat extends StatelessWidget {
  const QuizLeaderboardStat({
    super.key,
    required this.points,
    required this.attempts,
    this.textStyle,
    this.compact = false,
  });

  final int points;
  final int attempts;
  final TextStyle? textStyle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 12.r : 14.r;
    final valueStyle = textStyle ??
        AppTextStyles.goldNumeric(context).copyWith(
          fontSize: compact ? 12.sp : 14.sp,
        );
    final gap = compact ? 8.w : 12.w;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MetricIcon(
          icon: Icons.stars_rounded,
          value: points,
          iconSize: iconSize,
          valueStyle: valueStyle,
        ),
        SizedBox(width: gap),
        _MetricIcon(
          icon: Icons.replay_rounded,
          value: attempts,
          iconSize: iconSize,
          valueStyle: valueStyle,
        ),
      ],
    );
  }
}

class _MetricIcon extends StatelessWidget {
  const _MetricIcon({
    required this.icon,
    required this.value,
    required this.iconSize,
    required this.valueStyle,
  });

  final IconData icon;
  final int value;
  final double iconSize;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: AppColors.goldLight),
        SizedBox(width: 3.w),
        Text('$value', style: valueStyle),
      ],
    );
  }
}

String quizLeaderboardStatLabel(AppLocalizations l10n, int points, int attempts) {
  return l10n.leaderboardQuizStat(points, attempts);
}
