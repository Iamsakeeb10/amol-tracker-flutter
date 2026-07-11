import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/report_calculator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';

class ReportAmalBreakdownList extends StatelessWidget {
  const ReportAmalBreakdownList({super.key, required this.stats});

  final List<ReportAmalStat> stats;

  Color _rateColor(double rate) {
    if (rate >= 0.8) return AppColors.success;
    if (rate >= 0.5) return AppColors.gold;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    return CardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 0.5, color: AppColors.cardBorder),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      stats[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  SizedBox(
                    width: 80.w,
                    child: ScoreBar(
                      value: stats[i].rate,
                      height: 4,
                      color: _rateColor(stats[i].rate),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  SizedBox(
                    width: 40.w,
                    child: Text(
                      '${(stats[i].rate * 100).round()}%',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: _rateColor(stats[i].rate),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ReportInsightsCard extends StatelessWidget {
  const ReportInsightsCard({super.key, required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = <({IconData icon, String text})>[];

    if (summary.bestDayWeekday != null && summary.bestDayScore != null) {
      rows.add((
        icon: Icons.emoji_events_outlined,
        text: l10n.reportsBestDayInsight(
          summary.bestDayWeekday!,
          summary.bestDayScore!,
        ),
      ));
    }
    if (summary.weakestAmal != null) {
      final w = summary.weakestAmal!;
      rows.add((
        icon: Icons.warning_amber_rounded,
        text: l10n.reportsWeakestAmalInsight(
          w.label,
          w.doneCount,
          w.eligibleDays,
        ),
      ));
    }
    if (summary.strongestAmal != null) {
      final s = summary.strongestAmal!;
      rows.add((
        icon: Icons.star_outline_rounded,
        text: l10n.reportsStrongestAmalInsight(
          s.label,
          s.doneCount,
          s.eligibleDays,
        ),
      ));
    }
    if (summary.trendDelta != null) {
      final delta = summary.trendDelta!;
      if (delta > 0) {
        rows.add((
          icon: Icons.trending_up_rounded,
          text: l10n.reportsTrendUp(delta),
        ));
      } else if (delta < 0) {
        rows.add((
          icon: Icons.trending_down_rounded,
          text: l10n.reportsTrendDown(delta.abs()),
        ));
      } else {
        rows.add((
          icon: Icons.trending_flat_rounded,
          text: l10n.reportsTrendFlat,
        ));
      }
    }
    if (summary.rankInfo != null) {
      rows.add((
        icon: Icons.groups_outlined,
        text: l10n.reportsRankInsight(summary.rankInfo!.rank),
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return CardContainer(
      color: AppColors.goldCard,
      borderColor: AppColors.goldBorder,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(rows[i].icon, size: 18.r, color: AppColors.gold),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    rows[i].text,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontSize: 12.sp,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ReportHadithCard extends StatelessWidget {
  const ReportHadithCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Text(
        text,
        style: AppTextStyles.bodyMedium(context).copyWith(
          fontSize: 13.sp,
          fontStyle: FontStyle.italic,
          height: 1.65,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
