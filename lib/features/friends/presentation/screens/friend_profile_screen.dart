import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/streak_badge.dart';

class FriendProfileScreen extends StatelessWidget {
  final String friendId;
  const FriendProfileScreen({super.key, required this.friendId});

  MockUser get _user => kFriends.firstWhere(
        (u) => u.id == friendId,
        orElse: () => kFriends.first,
      );

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/friends'),
        ),
        title: Text('Friend', style: AppTextStyles.headlineMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
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
          const SizedBox(height: 14),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              StreakBadge(days: user.currentStreak),
              const Pill(text: 'Top scorer', icon: Icons.emoji_events_outlined),
            ],
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: [
                StatCard(
                  label: 'Streak',
                  value: '${user.currentStreak}',
                  sublabel: 'days',
                  icon: Icons.local_fire_department_outlined,
                ),
                StatCard(
                  label: 'Best',
                  value: '${user.bestStreak}',
                  sublabel: 'days',
                  icon: Icons.workspace_premium_outlined,
                ),
                StatCard(
                  label: 'Today',
                  value: '${user.todayScore}',
                  sublabel: 'of 100',
                  icon: Icons.today_outlined,
                ),
                StatCard(
                  label: 'This week',
                  value: '${user.weeklyScore}',
                  sublabel: 'pts',
                  icon: Icons.trending_up,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text("Today's amal", style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          _AmalGrid(user: user),
          const SizedBox(height: 18),
          Text('This week', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          const _MiniWeekChart(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dua sent (mock)')),
                    );
                  },
                  icon: const Icon(Icons.favorite_outline, size: 16),
                  label: const Text('Send Dua'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_remove_outlined, size: 16),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmalGrid extends StatelessWidget {
  final MockUser user;
  const _AmalGrid({required this.user});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(9, (i) {
        final field = kAmalFields[i];
        final h = (user.id.hashCode + i) % 4;
        final done = h > 0;
        return CardContainer(
          padding: const EdgeInsets.all(10),
          color: done ? AppColors.goldCard : AppColors.cardDark,
          borderColor: done ? AppColors.goldBorder : AppColors.cardBorder,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                field.icon,
                color: done ? AppColors.gold : AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(height: 4),
              field.isNumeric && done
                  ? Text(
                      '${(user.id.hashCode + i) % 5 + 1}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    )
                  : Icon(
                      done ? Icons.check : Icons.close,
                      size: 14,
                      color: done ? AppColors.success : AppColors.danger,
                    ),
              const SizedBox(height: 2),
              Text(
                kAmalShortLabels[field.id] ?? '',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 9),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MiniWeekChart extends StatelessWidget {
  const _MiniWeekChart();

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: SizedBox(
        height: 90,
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
                        Container(
                          height: 60 * b.value,
                          decoration: BoxDecoration(
                            color: b.missed ? AppColors.danger : AppColors.gold,
                            borderRadius: BorderRadius.circular(4),
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
