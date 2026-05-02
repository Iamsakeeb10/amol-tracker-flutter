import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MORE',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Account', style: AppTextStyles.displayMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push(AppRoutes.dev),
                icon: const Icon(Icons.bug_report_outlined),
                color: AppColors.textMuted,
                tooltip: 'Dev menu',
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yousuf Khan',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View profile',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                StreakBadge(days: kCurrentUser.currentStreak),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'EXPLORE'),
          CardContainer(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          const SizedBox(height: 18),
          const SectionHeader(title: 'PREFERENCES'),
          CardContainer(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          const SizedBox(height: 18),
          const SectionHeader(title: 'EMPTY / DEV'),
          CardContainer(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
