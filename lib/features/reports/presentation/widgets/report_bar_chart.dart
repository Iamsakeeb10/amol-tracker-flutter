import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/default_amal_fields.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/report_calculator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/device_tier_provider.dart';

class ReportBarChart extends ConsumerWidget {
  const ReportBarChart({
    super.key,
    required this.bars,
  });

  final List<ReportBarPoint> bars;

  Color _barColor(int score, bool hasLog, int barMax) {
    if (!hasLog) return AppColors.cardBorder;
    final ratio = barMax <= 0 ? 0.0 : score / barMax;
    if (ratio >= 0.8) return AppColors.success;
    if (ratio >= 0.5) return AppColors.gold;
    if (ratio > 0) return AppColors.danger;
    return AppColors.cardBorder;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bars.isEmpty) return const SizedBox.shrink();
    final reduceMotion = ref.watch(reduceMotionProvider);
    final l10n = AppLocalizations.of(context)!;
    final hasSpecialTime = bars.any((b) => b.specialTimeApplied);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 88.h,
          padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 0),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(AppRadius.md.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < bars.length; i++) ...[
                if (i > 0) SizedBox(width: 5.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final barMax = bars[i]
                                  .maxScore
                                  .clamp(1, kDefaultMaxDailyScore);
                              final ratio = bars[i].hasLog
                                  ? (bars[i].score / barMax).clamp(0.0, 1.0)
                                  : 0.0;
                              final height = (constraints.maxHeight * ratio)
                                  .clamp(3.0, constraints.maxHeight);
                              final color = _barColor(
                                bars[i].score,
                                bars[i].hasLog,
                                barMax,
                              );
                              final barColor = bars[i].specialTimeApplied
                                  ? color.withValues(alpha: 0.7)
                                  : color;
                              final bar = Container(
                                width: double.infinity,
                                height: height,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(3.r),
                                  ),
                                ),
                              );
                              if (reduceMotion) return bar;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOut,
                                width: double.infinity,
                                height: height,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(3.r),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        bars[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          fontSize: 8.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (hasSpecialTime) ...[
          SizedBox(height: 6.h),
          Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  l10n.reportsSpecialTimeLegendHint,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontSize: 10.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
