import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';
import '../../../../shared/widgets/streak_badge.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _periodIndex = 0;
  static const _periods = ['Weekly', 'Daily', 'Streak'];

  List<MockUser> get _ranked {
    final list = [...kFriends, kCurrentUser];
    list.sort((a, b) {
      switch (_periodIndex) {
        case 1:
          return b.todayScore.compareTo(a.todayScore);
        case 2:
          return b.currentStreak.compareTo(a.currentStreak);
        default:
          return b.weeklyScore.compareTo(a.weeklyScore);
      }
    });
    return list;
  }

  int _statValue(MockUser u) {
    switch (_periodIndex) {
      case 1:
        return u.todayScore;
      case 2:
        return u.currentStreak;
      default:
        return u.weeklyScore;
    }
  }

  String _statLabel() {
    switch (_periodIndex) {
      case 1:
        return 'pts';
      case 2:
        return 'days';
      default:
        return 'pts';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ranked = _ranked;
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/more'),
        ),
        title: Text('Leaderboard', style: AppTextStyles.headlineMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
        children: [
          _Tabs(
            value: _periodIndex,
            options: _periods,
            onChanged: (i) => setState(() => _periodIndex = i),
          ),
          const SizedBox(height: 16),
          _Podium(top3: ranked.take(3).toList(), getStat: _statValue),
          const SizedBox(height: 18),
          ...ranked.asMap().entries.map((e) {
            final rank = e.key + 1;
            final user = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RankRow(
                rank: rank,
                user: user,
                statValue: _statValue(user),
                statLabel: _statLabel(),
                isYou: user.id == 'me',
              ),
            );
          }),
          const SizedBox(height: 16),
          CardContainer.gold(
            child: Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.goldLight,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Keep climbing — every amal counts.',
                    style: AppTextStyles.bodyLarge.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int value;
  final List<String> options;
  final ValueChanged<int> onChanged;
  const _Tabs({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final selected = i == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
                alignment: Alignment.center,
                child: Text(
                  options[i],
                  style: AppTextStyles.button.copyWith(
                    fontSize: 12,
                    color: selected
                        ? AppColors.emeraldDeep
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<MockUser> top3;
  final int Function(MockUser u) getStat;
  const _Podium({required this.top3, required this.getStat});

  @override
  Widget build(BuildContext context) {
    if (top3.length < 3) return const SizedBox();
    final order = [top3[1], top3[0], top3[2]];
    final heights = [70.0, 100.0, 60.0];
    final ranks = [2, 1, 3];

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final user = order[i];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AvatarChip(
                    initial: user.initial,
                    color: user.avatarColor,
                    size: ranks[i] == 1 ? 56 : 44,
                    ring: ranks[i] == 1,
                    fontSize: ranks[i] == 1 ? 22 : 18,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.name,
                    style: AppTextStyles.bodyLarge.copyWith(fontSize: 12),
                  ),
                  Text(
                    '${getStat(user)}',
                    style: AppTextStyles.goldNumeric.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: heights[i],
                    decoration: BoxDecoration(
                      color: ranks[i] == 1
                          ? AppColors.gold
                          : AppColors.goldCard,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      border: Border.all(color: AppColors.goldBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${ranks[i]}',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: ranks[i] == 1
                            ? AppColors.emeraldDeep
                            : AppColors.gold,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final MockUser user;
  final int statValue;
  final String statLabel;
  final bool isYou;

  const _RankRow({
    required this.rank,
    required this.user,
    required this.statValue,
    required this.statLabel,
    required this.isYou,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      color: isYou ? AppColors.goldCard : AppColors.cardDark,
      borderColor: isYou ? AppColors.goldBorder : AppColors.cardBorder,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: AppTextStyles.goldNumeric.copyWith(fontSize: 18),
            ),
          ),
          AvatarChip(initial: user.initial, color: user.avatarColor, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: AppTextStyles.bodyLarge.copyWith(fontSize: 13),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 6),
                      const Pill(
                        text: 'you',
                        color: AppColors.goldCard,
                        textColor: AppColors.gold,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                ScoreBar(value: statValue / 700, height: 4),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$statValue',
            style: AppTextStyles.goldNumeric.copyWith(fontSize: 16),
          ),
          const SizedBox(width: 2),
          Text(
            statLabel,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
