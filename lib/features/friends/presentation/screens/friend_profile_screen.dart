import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/utils/dua_push_debug.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../models/badge_model.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/badge_tile.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/streak_badge.dart';
import '../../../../l10n/app_localizations.dart';

class FriendProfileScreen extends StatelessWidget {
  final String friendId;
  const FriendProfileScreen({super.key, required this.friendId});

  MockUser get _user => kFriends.firstWhere(
    (u) => u.id == friendId,
    orElse: () => kFriends.first,
  );

  List<String> _mockUnlockedBadgeIds(int streak) {
    return kBadgeDefinitions
        .where(
          (badge) =>
              badge.streakThreshold != null && streak >= badge.streakThreshold!,
        )
        .map((badge) => badge.id)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = _user;
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/friends'),
        ),
        title: Text(l10n.friend, style: AppTextStyles.headlineMedium(context)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(0, 8.h, 0, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Center(
                    child: AvatarChip(
                      initial: user.initial,
                      color: user.avatarColor,
                      size: 84,
                      ring: true,
                      fontSize: 32,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      user.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.displayMedium(context),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8.w,
                    children: [
                      StreakBadge(days: user.currentStreak),
                      Pill(
                        text: l10n.topScorer,
                        icon: Icons.emoji_events_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(4.w, 18.h, 4.w, 0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 10.w,
                childAspectRatio: profileStatGridAspectRatio(
                  context,
                  crossAxisCount: 2,
                  extraHorizontalPadding: 8,
                  crossAxisSpacing: 10,
                  minCellHeight: 108,
                ),
              ),
              delegate: SliverChildListDelegate([
                StatCard(
                  label: l10n.streak,
                  value: '${user.currentStreak}',
                  sublabel: l10n.historyDays,
                  icon: Icons.local_fire_department_rounded,
                  accentColor: AppColors.goldLight,
                  prominent: true,
                ),
                StatCard(
                  label: l10n.best,
                  value: '${user.bestStreak}',
                  sublabel: l10n.historyDays,
                  icon: Icons.workspace_premium_rounded,
                  accentColor: AppColors.goldPale,
                  prominent: true,
                ),
                StatCard(
                  label: l10n.today,
                  value: '${user.todayScore}',
                  sublabel: 'of 100',
                  icon: Icons.today_rounded,
                  accentColor: AppColors.success,
                  prominent: true,
                ),
                StatCard(
                  label: l10n.thisWeek,
                  value: '${user.weeklyScore}',
                  sublabel: l10n.pointsAbbr,
                  icon: Icons.trending_up_rounded,
                  accentColor: AppColors.warning,
                  prominent: true,
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 18.h),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.badges,
                    style: AppTextStyles.headlineMedium(context),
                  ),
                  SizedBox(height: 8.h),
                  ProfileBadgesGrid(
                    unlockedBadgeIds: _mockUnlockedBadgeIds(user.currentStreak),
                    currentStreak: user.currentStreak,
                    extraHorizontalPadding: 8,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 18.h),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.todaysAmal,
                style: AppTextStyles.headlineMedium(context),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 8.h),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                childAspectRatio: 1.1,
              ),
              itemCount: kAmalFields.length,
              itemBuilder: (context, index) =>
                  _AmalGridCell(user: user, fieldIndex: index),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 18.h),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.thisWeek,
                    style: AppTextStyles.headlineMedium(context),
                  ),
                  SizedBox(height: 8.h),
                  const _MiniWeekChart(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(0, 18.h, 0, 24.h),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        logDuaPushDebug(
                          'friend profile send dua tapped (mock UI only): '
                          'friendId=$friendId — no Firestore write or push',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.duaSentMock)),
                        );
                      },
                      icon: Icon(Icons.favorite_outline, size: 16.r),
                      label: Text(l10n.sendDua),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.emeraldDeep,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.person_remove_outlined, size: 16.r),
                      label: Text(l10n.remove),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.4),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmalGridCell extends StatelessWidget {
  final MockUser user;
  final int fieldIndex;
  const _AmalGridCell({required this.user, required this.fieldIndex});

  @override
  Widget build(BuildContext context) {
    final field = kAmalFields[fieldIndex];
    final h = (user.id.hashCode + fieldIndex) % 4;
    final done = h > 0;
    return CardContainer(
      padding: EdgeInsets.all(10.r),
      color: done ? AppColors.goldCard : AppColors.cardDark,
      borderColor: done ? AppColors.goldBorder : AppColors.cardBorder,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            amalFieldIcon(field.id),
            color: done ? AppColors.gold : AppColors.textMuted,
            size: 18.r,
          ),
          SizedBox(height: 4.h),
          field.type == AmalType.numeric && done
              ? Text(
                  '${(user.id.hashCode + fieldIndex) % 5 + 1}',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                )
              : Icon(
                  done ? Icons.check : Icons.close,
                  size: 14.r,
                  color: done ? AppColors.success : AppColors.danger,
                ),
          SizedBox(height: 2.h),
          Text(
            kAmalShortLabels[field.id] ?? '',
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(fontSize: 9.sp),
          ),
        ],
      ),
    );
  }
}

class _MiniWeekChart extends StatelessWidget {
  const _MiniWeekChart();

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: SizedBox(
        height: 90.h,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: kWeeklyBars
              .map(
                (b) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 60.h * b.value,
                          decoration: BoxDecoration(
                            color: b.missed ? AppColors.danger : AppColors.gold,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          b.label,
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(fontSize: 10.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
