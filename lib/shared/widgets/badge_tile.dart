import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/badge_model.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../l10n/app_localizations.dart';
import 'card_container.dart';
import 'score_bar.dart';

class BadgeTile extends StatelessWidget {
  final BadgeDefinition badge;
  final bool unlocked;
  final double progress;

  const BadgeTile({
    super.key,
    required this.badge,
    required this.unlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localizedTitle = _titleFor(l10n);
    final localizedDescription = _descriptionFor(l10n);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 130.h || constraints.maxWidth < 158.w;
        final pad = (compact ? AppSpacing.sm : AppSpacing.md).r;
        final iconSize = (compact ? 34 : 40).r;
        final iconInner = (compact ? 17 : 20).r;

        return CardContainer(
          padding: EdgeInsets.all(pad),
          color: unlocked ? AppColors.goldCard : AppColors.cardDark,
          borderColor: unlocked ? AppColors.goldBorder : AppColors.cardBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: unlocked
                      ? AppColors.gold
                      : AppColors.cardBorder.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  badge.icon,
                  color: unlocked ? AppColors.emeraldDeep : AppColors.textMuted,
                  size: iconInner,
                ),
              ),
              SizedBox(height: (compact ? 6 : 10).h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedTitle,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontSize: (compact ? 12 : 13).sp,
                        fontWeight: FontWeight.w500,
                        color: unlocked
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Expanded(
                      child: Text(
                        localizedDescription,
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(fontSize: (compact ? 10 : 11).sp),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!unlocked) ...[
                      SizedBox(height: (compact ? 6 : 8).h),
                      ScoreBar(value: progress, height: 4),
                      SizedBox(height: (compact ? 3 : 4).h),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(fontSize: 10.sp, color: AppColors.gold),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _titleFor(AppLocalizations l10n) {
    switch (badge.id) {
      case 'threeDays':
        return l10n.badgeThreeDaysTitle;
      case 'sevenDays':
        return l10n.badgeSevenDaysTitle;
      case 'fourteenDays':
        return l10n.badgeFourteenDaysTitle;
      case 'thirtyDays':
        return l10n.badgeThirtyDaysTitle;
      case 'sixtyDays':
        return l10n.badgeSixtyDaysTitle;
      case 'hundredDays':
        return l10n.badgeHundredDaysTitle;
      case 'topOfCommunity':
        return l10n.badgeTopCommunityTitle;
      case 'perfectWeek':
        return l10n.badgePerfectWeekTitle;
      default:
        return badge.title;
    }
  }

  String _descriptionFor(AppLocalizations l10n) {
    switch (badge.id) {
      case 'threeDays':
        return l10n.badgeThreeDaysDesc;
      case 'sevenDays':
        return l10n.badgeSevenDaysDesc;
      case 'fourteenDays':
        return l10n.badgeFourteenDaysDesc;
      case 'thirtyDays':
        return l10n.badgeThirtyDaysDesc;
      case 'sixtyDays':
        return l10n.badgeSixtyDaysDesc;
      case 'hundredDays':
        return l10n.badgeHundredDaysDesc;
      case 'topOfCommunity':
        return l10n.badgeTopCommunityDesc;
      case 'perfectWeek':
        return l10n.badgePerfectWeekDesc;
      default:
        return badge.description;
    }
  }
}
