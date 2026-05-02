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
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/streak_badge.dart';
import '../../../../shared/widgets/toggle_row.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unread =
        kNotifications.where((n) => n.unread).length;
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
                      'MORE',
                      style: AppTextStyles.label(context).copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text('Account', style: AppTextStyles.displayMedium(context)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push(AppRoutes.dev),
                icon: Icon(Icons.bug_report_outlined, size: 22.r),
                color: AppColors.textMuted,
                tooltip: 'Dev menu',
              ),
            ],
          ),
          SizedBox(height: 12.h),
          CardContainer(
            onTap: () => context.push(AppRoutes.profile),
            child: Row(
              children: [
                AvatarChip(
                  initial: kCurrentUser.initial,
                  color: kCurrentUser.avatarColor,
                  size: 44,
                  ring: true,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yousuf Khan',
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'View profile',
                        style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
                StreakBadge(days: kCurrentUser.currentStreak),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          const SectionHeader(title: 'EXPLORE'),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Column(
              children: [
                NavRow(
                  icon: Icons.leaderboard_outlined,
                  title: 'Leaderboard',
                  trailing: 'Weekly',
                  onTap: () => context.push(AppRoutes.leaderboard),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  trailing: unread == 0 ? null : '$unread',
                  onTap: () => context.push(AppRoutes.notifications),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.person_outline,
                  title: 'Profile & badges',
                  onTap: () => context.push(AppRoutes.profile),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          const SectionHeader(title: 'PREFERENCES'),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Column(
              children: [
                NavRow(
                  icon: Icons.tune_rounded,
                  title: 'Settings',
                  onTap: () => context.push(AppRoutes.settings),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.do_not_disturb_on_outlined,
                  title: 'Quiet hours',
                  trailing: '21:00 — 06:00',
                  onTap: () => context.push(AppRoutes.quietHours),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          const SectionHeader(title: 'EMPTY / DEV'),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Column(
              children: [
                NavRow(
                  icon: Icons.hourglass_empty,
                  title: 'Empty state preview',
                  onTap: () => context.push(AppRoutes.emptyState),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.list_alt_rounded,
                  title: 'Dev menu (all screens)',
                  onTap: () => context.push(AppRoutes.dev),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
