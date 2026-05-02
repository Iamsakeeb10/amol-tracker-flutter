import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => context.canPop() ? context.pop() : context.go('/more'),
        ),
        title: Text('Profile', style: AppTextStyles.headlineMedium(context)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 4.h, 0, 24.h),
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
          SizedBox(height: 12.h),
          Text(
            'Yousuf Khan',
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium(context),
          ),
          SizedBox(height: 4.h),
          Text(
            'Member since Jan 2025',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context),
          ),
          SizedBox(height: 12.h),
          Center(child: StreakBadge(days: kCurrentUser.currentStreak)),
          SizedBox(height: 18.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340.w;
              return GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                childAspectRatio: compact ? 1.02 : 1.28,
                children: [
                  StatCard(
                    label: 'Streak',
                    value: '${kCurrentUser.currentStreak}',
                    sublabel: 'days',
                    prominent: true,
                  ),
                  StatCard(
                    label: 'Best',
                    value: '${kCurrentUser.bestStreak}',
                    sublabel: 'days',
                    prominent: true,
                  ),
                  StatCard(
                    label: 'Avg',
                    value: '78',
                    sublabel: '/100',
                    prominent: true,
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 18.h),
          Text('This week', style: AppTextStyles.headlineMedium(context)),
          SizedBox(height: 8.h),
          const _WeekChart(),
          SizedBox(height: 18.h),
          Text('Badges', style: AppTextStyles.headlineMedium(context)),
          SizedBox(height: 8.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340.w;
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 10.w,
                childAspectRatio: compact ? 1.05 : 1.5,
                children: kBadges.map((b) => BadgeTile(badge: b)).toList(),
              );
            },
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
        height: 130.h,
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
                        Text(
                          '${(b.value * 100).round()}',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            fontSize: 9.sp,
                            color: b.missed
                                ? AppColors.danger
                                : AppColors.gold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          height: 80.h * b.value,
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
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(4.r),
                            ),
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
