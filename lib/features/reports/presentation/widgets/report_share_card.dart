import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/report_calculator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/report_provider.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/streak_badge.dart';
import '../../../../core/constants/amal_fields.dart';
import 'report_bar_chart.dart';
import 'report_insights_section.dart';
import 'report_prayer_breakdown.dart';

/// Branded, padded layout used when exporting a report as an image.
class ReportShareCard extends StatelessWidget {
  const ReportShareCard({
    super.key,
    required this.summary,
    required this.title,
    required this.dateMainLabel,
    required this.dateSubLabel,
    required this.maxScore,
    required this.periodType,
    required this.fields,
  });

  final ReportSummary summary;
  final String title;
  final String dateMainLabel;
  final String dateSubLabel;
  final int maxScore;
  final ReportPeriodType periodType;
  final List<AmalField> fields;

  static const iconAsset = 'assets/images/icon_fg.png';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dash = l10n.reportsEmDash;
    final avg = summary.hasScoredLogs
        ? summary.avgScore.round().toString()
        : dash;
    final streakValue = summary.liveCurrentStreak ?? summary.bestStreakInPeriod;
    final streakLabel = summary.liveCurrentStreak != null
        ? l10n.reportsCurrentStreak
        : l10n.reportsBestStreak;
    final rankValue = summary.rankInfo != null
        ? '#${summary.rankInfo!.rank}'
        : dash;
    final rankSublabel = summary.rankInfo != null
        ? l10n.reportsCommunityRank
        : l10n.reportsRankUnavailable;
    final chartLabel =
        summary.eligibleDays > ReportCalculator.bucketThresholdDays
        ? l10n.reportsChartWeekly
        : l10n.reportsChartDaily;

    return ColoredBox(
      color: AppColors.emeraldDeep,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 28.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _BrandHeader(appTitle: l10n.appTitle),
            SizedBox(height: 16.h),
            Text(
              dateMainLabel,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              dateSubLabel,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall(context),
            ),
            SizedBox(height: 16.h),
            CardContainer(
              color: AppColors.goldCard,
              borderColor: AppColors.goldBorder,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.label(context).copyWith(
                                  color: AppColors.goldLight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Pill(
                                text: l10n.reportsDaysLogged(
                                  summary.daysLogged,
                                  summary.eligibleDays,
                                ),
                                color: AppColors.successLight,
                                textColor: AppColors.success,
                                icon: Icons.check_circle_outline,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              avg,
                              style: AppTextStyles.goldNumeric(context)
                                  .copyWith(
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              l10n.reportsAvgScore,
                              style: AppTextStyles.bodySmall(
                                context,
                              ).copyWith(fontSize: 10.sp),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.goldBorder,
                  ),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _ShareMiniStat(
                            value: '$streakValue',
                            label: streakLabel,
                          ),
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 0.5,
                          color: AppColors.goldBorder,
                        ),
                        Expanded(
                          child: _ShareMiniStat(
                            value: '${summary.consistency}%',
                            label: l10n.reportsConsistency,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.goldBorder,
                  ),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _ShareMiniStat(
                            value: summary.bestDayScore?.toString() ?? dash,
                            label: l10n.reportsBestDayScore,
                          ),
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 0.5,
                          color: AppColors.goldBorder,
                        ),
                        Expanded(
                          child: _ShareMiniStat(
                            value: periodType == ReportPeriodType.custom
                                ? '${summary.eligibleDays}'
                                : rankValue,
                            label: periodType == ReportPeriodType.custom
                                ? l10n.reportsDaysInRange
                                : rankSublabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (summary.logs.isEmpty) ...[
              SizedBox(height: 24.h),
              Text(
                l10n.reportsEmptyPeriod,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textMuted),
              ),
            ] else ...[
              if (summary.bars.isNotEmpty) ...[
                SizedBox(height: 16.h),
                SectionHeader(title: chartLabel),
                ReportBarChart(bars: summary.bars, maxScore: maxScore),
              ],
              if (summary.amalBreakdown.isNotEmpty) ...[
                SizedBox(height: 16.h),
                SectionHeader(title: l10n.reportsAmalBreakdown),
                ReportAmalBreakdownList(stats: summary.amalBreakdown),
                SizedBox(height: 16.h),
                SectionHeader(title: l10n.prayerBreakdown),
                ReportPrayerBreakdownSection(
                  logs: summary.logs,
                  fields: fields,
                ),
              ],
              SizedBox(height: 16.h),
              SectionHeader(title: l10n.reportsInsights),
              ReportInsightsCard(summary: summary),
              if (summary.hadithText != null &&
                  summary.hadithText!.isNotEmpty) ...[
                SizedBox(height: 16.h),
                SectionHeader(title: l10n.reportsHadithOfPeriod),
                ReportHadithCard(text: summary.hadithText!),
              ],
            ],
            SizedBox(height: 20.h),
            Text(
              l10n.appTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.gold.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.appTitle});

  final String appTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40.r,
          height: 40.r,
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: AppColors.goldCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.goldBorder),
          ),
          child: Image.asset(
            ReportShareCard.iconAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.mosque_outlined,
              color: AppColors.gold,
              size: 20.r,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldLight,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                AppLocalizations.of(context)!.myReports,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShareMiniStat extends StatelessWidget {
  const _ShareMiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.goldNumeric(context).copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontSize: 10.sp,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
