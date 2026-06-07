import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/score_bar.dart';
import 'quiz_helpers.dart';

class QuizTimerBar extends ConsumerStatefulWidget {
  const QuizTimerBar({
    super.key,
    required this.totalSeconds,
    required this.onExpired,
  });

  final int totalSeconds;
  final VoidCallback onExpired;

  @override
  ConsumerState<QuizTimerBar> createState() => QuizTimerBarState();
}

class QuizTimerBarState extends ConsumerState<QuizTimerBar> {
  Timer? _timer;
  late int _remainingSeconds;
  var _expired = false;

  int get elapsedSeconds => widget.totalSeconds - _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.totalSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _expired) return;
    if (_remainingSeconds <= 1) {
      setState(() => _remainingSeconds = 0);
      _expire();
      return;
    }
    setState(() => _remainingSeconds--);
  }

  void _expire() {
    if (_expired) return;
    _expired = true;
    _timer?.cancel();
    widget.onExpired();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = widget.totalSeconds <= 0
        ? 1.0
        : _remainingSeconds / widget.totalSeconds;
    final isLow = _remainingSeconds <= 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 16.r,
              color: isLow ? AppColors.danger : AppColors.goldLight,
            ),
            SizedBox(width: 6.w),
            Text(
              l10n.syllabusQuizTimeRemaining,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const Spacer(),
            Text(
              formatQuizDuration(_remainingSeconds),
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: isLow ? AppColors.danger : AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ScoreBar(
          value: progress,
          height: 6,
          color: isLow ? AppColors.danger : AppColors.gold,
        ),
      ],
    );
  }
}
