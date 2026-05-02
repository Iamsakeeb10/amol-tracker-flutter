import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => context.canPop() ? context.pop() : context.go('/more'),
        ),
        title: Text('Leaderboard', style: AppTextStyles.headlineMedium(context)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 4.h, 0, 24.h),
        children: [
          _Tabs(
            value: _periodIndex,
            options: _periods,
            onChanged: (i) => setState(() => _periodIndex = i),
          ),
          SizedBox(height: 16.h),
          _Podium(top3: ranked.take(3).toList(), getStat: _statValue),
          SizedBox(height: 18.h),
          ...ranked.asMap().entries.map((e) {
            final rank = e.key + 1;
            final user = e.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _RankRow(
                rank: rank,
                user: user,
                statValue: _statValue(user),
                statLabel: _statLabel(),
                isYou: user.id == 'me',
              ),
            );
          }),
          SizedBox(height: 16.h),
          CardContainer.gold(
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: AppColors.goldLight,
                  size: 20.r,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Keep climbing — every amal counts.',
                    style: AppTextStyles.bodyLarge(context).copyWith(fontSize: 13.sp),
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
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(99.r),
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
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: selected ? AppColors.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(99.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  options[i],
                  style: AppTextStyles.button(context).copyWith(
                    fontSize: 12.sp,
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
    final heights = [64.h, 88.h, 56.h];
    final ranks = [2, 1, 3];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340.w;
        return SizedBox(
          height: compact ? 216.h : 200.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final user = order[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
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
                      SizedBox(height: 6.h),
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge(context).copyWith(fontSize: 12.sp),
                      ),
                      Text(
                        '${getStat(user)}',
                        style: AppTextStyles.goldNumeric(context).copyWith(fontSize: 16.sp),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        height: compact ? heights[i] + 8.h : heights[i],
                        decoration: BoxDecoration(
                          color: ranks[i] == 1
                              ? AppColors.gold
                              : AppColors.goldCard,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(10.r),
                          ),
                          border: Border.all(color: AppColors.goldBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${ranks[i]}',
                          style: AppTextStyles.displayMedium(context).copyWith(
                            color: ranks[i] == 1
                                ? AppColors.emeraldDeep
                                : AppColors.gold,
                            fontSize: 26.sp,
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
      },
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          SizedBox(
            width: 28.w,
            child: Text(
              '$rank',
              style: AppTextStyles.goldNumeric(context).copyWith(fontSize: 18.sp),
            ),
          ),
          AvatarChip(initial: user.initial, color: user.avatarColor, size: 32),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: AppTextStyles.bodyLarge(context).copyWith(fontSize: 13.sp),
                    ),
                    if (isYou) ...[
                      SizedBox(width: 6.w),
                      const Pill(
                        text: 'you',
                        color: AppColors.goldCard,
                        textColor: AppColors.gold,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                ScoreBar(value: statValue / 700, height: 4),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '$statValue',
            style: AppTextStyles.goldNumeric(context).copyWith(fontSize: 16.sp),
          ),
          SizedBox(width: 2.w),
          Text(
            statLabel,
            style: AppTextStyles.bodySmall(context).copyWith(fontSize: 10.sp),
          ),
        ],
      ),
    );
  }
}
