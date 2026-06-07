import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/time_display_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/streak_badge.dart';
import '../../../../shared/widgets/toggle_row.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;
    final prefs = ref.watch(notificationPrefsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);
    final quietHoursLabel =
        '${formatBdTime(context, prefs.quietFrom)} — ${formatBdTime(context, prefs.quietTo)}';
    final rawName = user?.name ?? '';
    final displayName = rawName.trim().isEmpty ? l10n.profile : rawName.trim();
    final initial = displayName.substring(0, 1).toUpperCase();
    final streak = user?.currentStreak ?? 0;
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
                      l10n.more,
                      style: AppTextStyles.label(
                        context,
                      ).copyWith(color: AppColors.gold),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      l10n.account,
                      style: AppTextStyles.displayMedium(context),
                    ),
                  ],
                ),
              ),
              // IconButton(
              //   onPressed: () => context.push(AppRoutes.dev),
              //   icon: Icon(Icons.bug_report_outlined, size: 22.r),
              //   color: AppColors.textMuted,
              //   tooltip: l10n.devMenu,
              // ),
            ],
          ),
          SizedBox(height: 12.h),
          CardContainer(
            onTap: () => context.push(AppRoutes.profile),
            child: Row(
              children: [
                AvatarChip(
                  initial: user?.isAnonymousDisplay == true ? '🕌' : initial,
                  color: AppColors.gold,
                  size: 44,
                  ring: true,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        l10n.viewProfile,
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
                StreakBadge(days: streak),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          SectionHeader(title: l10n.exploreSection),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Column(
              children: [
                NavRow(
                  icon: Icons.leaderboard_outlined,
                  title: l10n.leaderboard,
                  trailing: l10n.weekly,
                  onTap: () => context.push(AppRoutes.leaderboard),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.notifications_outlined,
                  title: l10n.notifications,
                  trailing: unread == 0 ? null : '$unread',
                  onTap: () => context.push(AppRoutes.notifications),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.fiber_manual_record_outlined,
                  title: l10n.dhikrCounter,
                  onTap: () => context.push(AppRoutes.dhikr),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.person_outline,
                  title: l10n.profileAndBadges,
                  onTap: () => context.push(AppRoutes.profile),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          SectionHeader(title: l10n.preferencesSection),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Column(
              children: [
                NavRow(
                  icon: Icons.tune_rounded,
                  title: l10n.settings,
                  onTap: () => context.push(AppRoutes.settings),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.do_not_disturb_on_outlined,
                  title: l10n.quietHours,
                  trailing: quietHoursLabel,
                  onTap: () => context.push(AppRoutes.quietHours),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          // SectionHeader(title: l10n.emptyDevSection),
          // CardContainer(
          //   padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          //   child: Column(
          //     children: [
          //       NavRow(
          //         icon: Icons.hourglass_empty,
          //         title: l10n.emptyStatePreview,
          //         onTap: () => context.push(AppRoutes.emptyState),
          //       ),
          //       const Divider(),
          //       NavRow(
          //         icon: Icons.list_alt_rounded,
          //         title: l10n.devMenuAllScreens,
          //         onTap: () => context.push(AppRoutes.dev),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
