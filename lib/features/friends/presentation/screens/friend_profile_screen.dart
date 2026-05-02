import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => context.canPop() ? context.pop() : context.go('/friends'),
        ),
        title: Text('Friend', style: AppTextStyles.headlineMedium(context)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 8.h, 0, 24.h),
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
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium(context),
          ),
          SizedBox(height: 8.h),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.w,
            children: [
              StreakBadge(days: user.currentStreak),
              const Pill(text: 'Top scorer', icon: Icons.emoji_events_outlined),
            ],
          ),
          SizedBox(height: 18.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340.w;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10.h,
                  crossAxisSpacing: 10.w,
                  childAspectRatio: compact ? 1.72 : 2.15,
                  children: [
                    StatCard(
                      label: 'Streak',
                      value: '${user.currentStreak}',
                      sublabel: 'days',
                      icon: Icons.local_fire_department_rounded,
                      accentColor: AppColors.goldLight,
                      prominent: true,
                    ),
                    StatCard(
                      label: 'Best',
                      value: '${user.bestStreak}',
                      sublabel: 'days',
                      icon: Icons.workspace_premium_rounded,
                      accentColor: AppColors.goldPale,
                      prominent: true,
                    ),
                    StatCard(
                      label: 'Today',
                      value: '${user.todayScore}',
                      sublabel: 'of 100',
                      icon: Icons.today_rounded,
                      accentColor: AppColors.success,
                      prominent: true,
                    ),
                    StatCard(
                      label: 'This week',
                      value: '${user.weeklyScore}',
                      sublabel: 'pts',
                      icon: Icons.trending_up_rounded,
                      accentColor: AppColors.warning,
                      prominent: true,
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 18.h),
          Text("Today's amal", style: AppTextStyles.headlineMedium(context)),
          SizedBox(height: 8.h),
          _AmalGrid(user: user),
          SizedBox(height: 18.h),
          Text('This week', style: AppTextStyles.headlineMedium(context)),
          SizedBox(height: 8.h),
          const _MiniWeekChart(),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dua sent (mock)')),
                    );
                  },
                  icon: Icon(Icons.favorite_outline, size: 16.r),
                  label: const Text('Send Dua'),
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
                  label: const Text('Remove'),
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
      mainAxisSpacing: 8.h,
      crossAxisSpacing: 8.w,
      children: List.generate(9, (i) {
        final field = kAmalFields[i];
        final h = (user.id.hashCode + i) % 4;
        final done = h > 0;
        return CardContainer(
          padding: EdgeInsets.all(10.r),
          color: done ? AppColors.goldCard : AppColors.cardDark,
          borderColor: done ? AppColors.goldBorder : AppColors.cardBorder,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                field.icon,
                color: done ? AppColors.gold : AppColors.textMuted,
                size: 18.r,
              ),
              SizedBox(height: 4.h),
              field.isNumeric && done
                  ? Text(
                      '${(user.id.hashCode + i) % 5 + 1}',
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
                style: AppTextStyles.bodySmall(context).copyWith(fontSize: 9.sp),
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
                          style: AppTextStyles.bodySmall(context).copyWith(fontSize: 10.sp),
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
