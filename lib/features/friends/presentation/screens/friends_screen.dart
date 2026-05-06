import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/streak_badge.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      padding: EdgeInsets.zero,
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FRIENDS',
                      style: AppTextStyles.label(context).copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text('Together', style: AppTextStyles.displayMedium(context)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.community),
                icon: Icon(Icons.add, size: 16.r),
                label: const Text('Invite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          const SectionHeader(title: 'ACTIVITY FEED'),
          ...kActivities.map(
            (a) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _ActivityRow(activity: a),
            ),
          ),
          SizedBox(height: 18.h),
          SectionHeader(
            title: 'YOUR GROUP',
            trailingText: 'MANAGE',
            onTrailingTap: () => context.push(AppRoutes.settings),
          ),
          _GroupCard(),
          SizedBox(height: 18.h),
          const SectionHeader(title: 'FRIENDS'),
          ...kFriends.map(
            (u) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _FriendCard(user: u),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final MockActivity activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      color: activity.isMilestone ? AppColors.goldCard : AppColors.cardDark,
      borderColor: activity.isMilestone
          ? AppColors.goldBorder
          : AppColors.cardBorder,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          AvatarChip(
            initial: activity.userInitial,
            color: activity.avatarColor,
            size: 32,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.text,
                  style: AppTextStyles.bodyLarge(context).copyWith(fontSize: 13.sp),
                ),
                SizedBox(height: 2.h),
                Text(
                  activity.time,
                  style: AppTextStyles.bodySmall(context).copyWith(fontSize: 10.sp),
                ),
              ],
            ),
          ),
          if (!activity.isMilestone)
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.goldBorder),
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 6.h,
                ),
                minimumSize: Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99.r),
                ),
              ),
              child: Text(
                'Send Dua',
                style: AppTextStyles.pill(context).copyWith(color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CardContainer(
      onTap: () => context.push(AppRoutes.community),
      color: AppColors.goldCard,
      borderColor: AppColors.goldBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kGroup.name,
                      style: AppTextStyles.headlineLarge(context).copyWith(fontSize: 18.sp),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${kGroup.memberCount} brothers · ${kGroup.description}',
                      style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
              StreakBadge(days: kGroup.groupStreak),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              StackedAvatars(
                avatars: kGroup.members
                    .take(4)
                    .map((m) => (initial: m.initial, color: m.avatarColor))
                    .toList(),
              ),
              const Spacer(),
              Text(
                'View sheet →',
                style: AppTextStyles.button(context).copyWith(color: AppColors.gold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final MockUser user;
  const _FriendCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      onTap: () => context.push('${AppRoutes.userProfile}/${user.id}'),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          AvatarChip(initial: user.initial, color: user.avatarColor),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                ScoreBar(value: user.todayScore / 100, height: 4),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Pill(
            text: user.doneToday ? 'done' : 'pending',
            color: user.doneToday
                ? AppColors.successLight
                : AppColors.cardBorder,
            textColor: user.doneToday
                ? AppColors.success
                : AppColors.textMuted,
          ),
          SizedBox(width: 8.w),
          Text(
            '${user.todayScore}',
            style: AppTextStyles.goldNumeric(context).copyWith(fontSize: 16.sp),
          ),
        ],
      ),
    );
  }
}
