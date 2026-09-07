import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/personal_amol_report_provider.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';
import '../../../personal_amol/presentation/widgets/personal_amol_icons.dart';

/// Personal-amol completion breakdown for reports / share card / profile.
///
/// Matches [ReportAmalBreakdownList] layout: card, dividers, score bar, rate %.
/// When [compact] is true (profile), rows are denser and show
/// completed/eligible under the name.
class ReportPersonalAmolBreakdown extends StatelessWidget {
  const ReportPersonalAmolBreakdown({
    super.key,
    required this.stats,
    this.compact = false,
  });

  final List<PersonalAmolReportStat> stats;
  final bool compact;

  Color _rateColor(double rate) {
    if (rate >= 0.8) return AppColors.success;
    if (rate >= 0.5) return AppColors.gold;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final rowPadV = compact ? 8.h : 10.h;
    final iconSize = compact ? 24.r : 28.r;
    final nameSize = compact ? 11.sp : 12.sp;
    final barWidth = compact ? 64.w : 80.w;
    final pctWidth = compact ? 36.w : 40.w;

    return CardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 0.5, color: AppColors.cardBorder),
            Builder(
              builder: (context) {
                final stat = stats[i];
                final pct = (stat.rate * 100).round();
                final daysLabel = l10n.personalAmolProgressLabel(
                  stat.completedDays,
                  stat.eligibleDays,
                );
                final semanticLabel = [
                  stat.name,
                  daysLabel,
                  '$pct%',
                  if (!stat.isActive) l10n.personalAmolDeleteSubtitle,
                ].join(', ');

                return Semantics(
                  label: semanticLabel,
                  child: Opacity(
                    opacity: stat.isActive ? 1 : 0.72,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: rowPadV,
                      ),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: Container(
                              width: iconSize,
                              height: iconSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.cardBorder,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: AmolIconView(
                                icon: stat.icon,
                                onFilled: false,
                                emojiSize: compact ? 12 : 14,
                                iconSize: compact ? 14 : 16,
                                fallbackText: stat.name,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stat.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyMedium(context)
                                      .copyWith(
                                    fontSize: nameSize,
                                    color: AppColors.textSecondary,
                                    fontStyle: stat.isActive
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  daysLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall(context)
                                      .copyWith(
                                    fontSize: compact ? 9.sp : 10.sp,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10.w),
                          ExcludeSemantics(
                            child: SizedBox(
                              width: barWidth,
                              child: ScoreBar(
                                value: stat.rate,
                                height: compact ? 3 : 4,
                                color: _rateColor(stat.rate),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          SizedBox(
                            width: pctWidth,
                            child: Text(
                              '$pct%',
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall(context).copyWith(
                                fontSize: compact ? 10.sp : 11.sp,
                                fontWeight: FontWeight.w600,
                                color: _rateColor(stat.rate),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
