import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/badge_tile.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/streak_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/more'),
        ),
        title: Text('Profile', style: AppTextStyles.headlineMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
        children: [
          Center(
            child: AvatarChip(
              initial: kCurrentUser.initial,
              color: kCurrentUser.avatarColor,
              size: 88,
              ring: true,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Yousuf Khan',
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Member since Jan 2025',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          Center(child: StreakBadge(days: kCurrentUser.currentStreak)),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.4,
            children: [
              StatCard(
                label: 'Streak',
                value: '${kCurrentUser.currentStreak}',
                sublabel: 'days',
              ),
              StatCard(
                label: 'Best',
                value: '${kCurrentUser.bestStreak}',
                sublabel: 'days',
              ),
              StatCard(label: 'Avg', value: '78', sublabel: '/100'),
            ],
          ),
          const SizedBox(height: 18),
          Text('This week', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          const _WeekChart(),
          const SizedBox(height: 18),
          Text('Badges', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: kBadges.map((b) => BadgeTile(badge: b)).toList(),
          ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart();

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: SizedBox(
        height: 130,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: kWeeklyBars
              .map(
                (b) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(b.value * 100).round()}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 9,
                            color: b.missed
                                ? AppColors.danger
                                : AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 80 * b.value,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: b.missed
                                  ? const [
                                      AppColors.danger,
                                      AppColors.dangerLight,
                                    ]
                                  : const [AppColors.gold, AppColors.goldLight],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          b.label,
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
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
