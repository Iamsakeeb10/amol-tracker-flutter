import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/badge_model.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../l10n/app_localizations.dart';
import 'card_container.dart';
import 'score_bar.dart';

/// Computes a grid aspect ratio that keeps [BadgeTile] cells tall enough on narrow screens.
double profileBadgeGridAspectRatio(
  BuildContext context, {
  int crossAxisCount = 2,
  double extraHorizontalPadding = 0,
  double crossAxisSpacing = 10,
  double minCellHeight = 188,
}) {
  final width = MediaQuery.sizeOf(context).width;
  const scaffoldHorizontalPadding = 40.0;
  final spacing = crossAxisSpacing.w * (crossAxisCount - 1);
  final cellWidth = (width -
          scaffoldHorizontalPadding.w -
          extraHorizontalPadding.w -
          spacing) /
      crossAxisCount;
  final cellHeight = minCellHeight.h;
  if (cellHeight <= 0) return 0.9;
  return cellWidth / cellHeight;
}

double badgeProgress(
  BadgeDefinition badge,
  int currentStreak,
  bool unlocked,
) {
  if (unlocked) return 1;
  if (badge.streakThreshold == null || badge.streakThreshold == 0) return 0;
  return (currentStreak / badge.streakThreshold!).clamp(0.0, 1.0);
}

class ProfileBadgesGrid extends StatelessWidget {
  const ProfileBadgesGrid({
    super.key,
    required this.unlockedBadgeIds,
    required this.currentStreak,
    this.extraHorizontalPadding = 0,
    this.crossAxisSpacing = 10,
  });

  final List<String> unlockedBadgeIds;
  final int currentStreak;
  final double extraHorizontalPadding;
  final double crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: crossAxisSpacing.w,
        childAspectRatio: profileBadgeGridAspectRatio(
          context,
          extraHorizontalPadding: extraHorizontalPadding,
          crossAxisSpacing: crossAxisSpacing,
        ),
      ),
      itemCount: kBadgeDefinitions.length,
      itemBuilder: (context, index) {
        final badge = kBadgeDefinitions[index];
        final unlocked = unlockedBadgeIds.contains(badge.id);
        return BadgeTile(
          badge: badge,
          unlocked: unlocked,
          progress: badgeProgress(badge, currentStreak, unlocked),
        );
      },
    );
  }
}

class ProfileBadgesSection extends StatelessWidget {
  const ProfileBadgesSection({
    super.key,
    required this.unlockedBadgeIds,
    required this.currentStreak,
    this.extraHorizontalPadding = 0,
    this.crossAxisSpacing = 10,
  });

  final List<String> unlockedBadgeIds;
  final int currentStreak;
  final double extraHorizontalPadding;
  final double crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(top: 18.h),
          sliver: SliverToBoxAdapter(
            child: Text(
              l10n.badges,
              style: AppTextStyles.headlineMedium(context),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(top: 8.h, bottom: 24.h),
          sliver: SliverToBoxAdapter(
            child: ProfileBadgesGrid(
              unlockedBadgeIds: unlockedBadgeIds,
              currentStreak: currentStreak,
              extraHorizontalPadding: extraHorizontalPadding,
              crossAxisSpacing: crossAxisSpacing,
            ),
          ),
        ),
      ],
    );
  }
}

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
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;
        final isCompact = maxHeight < 150.h || maxWidth < 158.w;
        final isTight = maxHeight.isFinite && maxHeight < 170.h;
        final pad = (isTight || isCompact ? AppSpacing.sm : AppSpacing.md).r;
        final iconSize = (isTight ? 30 : isCompact ? 34 : 40).r;
        final iconInner = (isTight ? 15 : isCompact ? 17 : 20).r;
        final titleSize = (isTight ? 11.0 : isCompact ? 12.0 : 13.0).sp;
        final descSize = (isTight ? 9.0 : isCompact ? 10.0 : 11.0).sp;
        final gapAfterIcon = (isTight ? 4 : isCompact ? 6 : 10).h;
        final gapAfterTitle = (isTight ? 2 : 3).h;
        final gapBeforeBar = (isTight ? 4 : isCompact ? 6 : 8).h;

        final innerHeight = maxHeight.isFinite
            ? (maxHeight - pad * 2).clamp(0.0, double.infinity)
            : null;
        final innerWidth = maxWidth.isFinite
            ? (maxWidth - pad * 2).clamp(0.0, double.infinity)
            : null;
        final contentWidth = innerWidth ?? maxWidth;

        Widget buildContent() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              SizedBox(height: gapAfterIcon),
              if (contentWidth.isFinite)
                SizedBox(
                  width: contentWidth,
                  child: Text(
                    localizedTitle,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      color: unlocked
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      height: 1.15,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                )
              else
                Text(
                  localizedTitle,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    color: unlocked
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                ),
              SizedBox(height: gapAfterTitle),
              if (contentWidth.isFinite)
                SizedBox(
                  width: contentWidth,
                  child: Text(
                    localizedDescription,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontSize: descSize,
                      height: 1.2,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: isTight ? 3 : 4,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                )
              else
                Text(
                  localizedDescription,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontSize: descSize,
                    height: 1.2,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: isTight ? 3 : 4,
                  softWrap: true,
                ),
              if (!unlocked) ...[
                SizedBox(height: gapBeforeBar),
                SizedBox(
                  width: contentWidth.isFinite ? contentWidth : null,
                  child: ScoreBar(value: progress, height: 4),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontSize: 10.sp,
                    color: AppColors.gold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          );
        }

        final content = buildContent();

        final Widget body;
        if (innerHeight != null && innerHeight > 0 && innerWidth != null) {
          body = SizedBox(
            height: innerHeight,
            width: innerWidth,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: innerWidth),
                  child: content,
                ),
              ),
            ),
          );
        } else {
          body = Center(child: content);
        }

        return CardContainer(
          padding: EdgeInsets.all(pad),
          color: unlocked ? AppColors.goldCard : AppColors.cardDark,
          borderColor: unlocked ? AppColors.goldBorder : AppColors.cardBorder,
          child: body,
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
