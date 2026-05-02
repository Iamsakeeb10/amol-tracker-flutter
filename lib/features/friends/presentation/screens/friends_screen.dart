import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FRIENDS',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Together', style: AppTextStyles.displayMedium),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.invite),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Invite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'ACTIVITY FEED'),
          ...kActivities.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActivityRow(activity: a),
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'YOUR GROUP',
            trailingText: 'MANAGE',
            onTrailingTap: () => context.push(AppRoutes.groupManage),
          ),
          _GroupCard(),
          const SizedBox(height: 18),
          const SectionHeader(title: 'FRIENDS'),
          ...kFriends.map(
            (u) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          AvatarChip(
            initial: activity.userInitial,
            color: activity.avatarColor,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.text,
                  style: AppTextStyles.bodyLarge.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.time,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              child: Text(
                'Send Dua',
                style: AppTextStyles.pill.copyWith(color: AppColors.gold),
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
      onTap: () => context.push(AppRoutes.groupSheet),
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
                      style: AppTextStyles.headlineLarge.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${kGroup.memberCount} brothers · ${kGroup.description}',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              StreakBadge(days: kGroup.groupStreak),
            ],
          ),
          const SizedBox(height: 12),
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
                style: AppTextStyles.button.copyWith(color: AppColors.gold),
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
      onTap: () => context.push('${AppRoutes.friendProfile}/${user.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          AvatarChip(initial: user.initial, color: user.avatarColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ScoreBar(value: user.todayScore / 100, height: 4),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Pill(
            text: user.doneToday ? 'done' : 'pending',
            color: user.doneToday
                ? AppColors.successLight
                : AppColors.cardBorder,
            textColor: user.doneToday
                ? AppColors.success
                : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            '${user.todayScore}',
            style: AppTextStyles.goldNumeric.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
