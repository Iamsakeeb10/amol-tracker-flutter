import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/admin_config.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/time_display_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/history_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/streak_badge.dart';
import '../../../../shared/widgets/toggle_row.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenViewed('more');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;
    final prefs = ref.watch(notificationPrefsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);
    final quietHoursLabel =
        '${formatBdTime(context, prefs.quietFrom)} — ${formatBdTime(context, prefs.quietTo)}';
    final rawName = user?.name ?? '';
    final displayName = rawName.trim().isEmpty ? l10n.profile : rawName.trim();
    final initial = displayName.substring(0, 1).toUpperCase();
    final streak = ref.watch(liveStreakProvider).value ?? user?.currentStreak ?? 0;
    final isFullAdmin = AdminConfig.isFullAdmin(user?.email, role: user?.role);
    final isListedModerator =
        ref.watch(isListedCourseModeratorProvider).value ?? false;
    final canManageCourses =
        AdminConfig.canAccessCourseAdmin(user?.email, role: user?.role) ||
        isListedModerator;
    return AppScaffold(handleExitBack: false,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
        children: [
          Row(
            children: [
              // const BottomTabBackButton(),
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
                  onTap: () {
                    AnalyticsService.instance.logFeatureTapped('leaderboard', screen: 'more');
                    context.push(AppRoutes.leaderboard);
                  },
                ),
                const Divider(),
                NavRow(
                  icon: Icons.assessment_outlined,
                  title: l10n.myReports,
                  onTap: () {
                    AnalyticsService.instance.logFeatureTapped('reports', screen: 'more');
                    context.push(AppRoutes.reports);
                  },
                ),
                const Divider(),
                NavRow(
                  icon: Icons.notifications_outlined,
                  title: l10n.notifications,
                  trailing: unread == 0 ? null : '$unread',
                  onTap: () {
                    AnalyticsService.instance.logFeatureTapped('notifications', screen: 'more');
                    context.push(AppRoutes.notifications);
                  },
                ),
                const Divider(),
                NavRow(
                  icon: Icons.calendar_month_outlined,
                  title: l10n.hijriCalendar,
                  onTap: () {
                    AnalyticsService.instance.logFeatureTapped('hijri_calendar', screen: 'more');
                    context.push(AppRoutes.hijriCalendar);
                  },
                ),
                const Divider(),
                NavRow(
                  icon: Icons.explore_outlined,
                  title: l10n.qiblaTitle,
                  onTap: () {
                    AnalyticsService.instance.logFeatureTapped('qibla', screen: 'more');
                    context.push(AppRoutes.qibla);
                  },
                ),
                const Divider(),
                NavRow(
                  icon: Icons.fiber_manual_record_outlined,
                  title: l10n.dhikrCounter,
                  onTap: () {
                    AnalyticsService.instance.logFeatureTapped('dhikr', screen: 'more');
                    context.push(AppRoutes.dhikr);
                  },
                ),
                const Divider(),
                NavRow(
                  icon: Icons.auto_awesome_outlined,
                  title: l10n.asmaUlHusna,
                  onTap: () {
                    AnalyticsService.instance.logFeatureTapped('asma_ul_husna', screen: 'more');
                    context.push(AppRoutes.asmaUlHusna);
                  },
                ),
                const Divider(),
                NavRow(
                  icon: Icons.menu_book_outlined,
                  title: l10n.navDua,
                  onTap: () {
                    AnalyticsService.instance.logFeatureTapped('dua', screen: 'more');
                    context.push(AppRoutes.dua);
                  },
                ),
                const Divider(),
                NavRow(
                  icon: Icons.auto_stories_outlined,
                  title: l10n.quranTitle,
                  onTap: () {
                    AnalyticsService.instance.logFeatureTapped('quran', screen: 'more');
                    context.push(AppRoutes.quran);
                  },
                ),
                const Divider(),
                NavRow(
                  icon: Icons.menu_book_outlined,
                  title: l10n.syllabusTitle,
                  onTap: () {
                    AnalyticsService.instance.logFeatureTapped('syllabus', screen: 'more');
                    context.push(AppRoutes.syllabus);
                  },
                ),
                const Divider(),
                NavRow(
                  icon: Icons.person_outline,
                  title: l10n.profileAndBadges,
                  onTap: () {
                    AnalyticsService.instance.logFeatureTapped('profile', screen: 'more');
                    context.push(AppRoutes.profile);
                  },
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
                  onTap: () {
                    AnalyticsService.instance.logFeatureTapped('settings', screen: 'more');
                    context.push(AppRoutes.settings);
                  },
                ),
                const Divider(),
                NavRow(
                  icon: Icons.do_not_disturb_on_outlined,
                  title: l10n.quietHours,
                  trailing: quietHoursLabel,
                  onTap: () {
                    AnalyticsService.instance.logFeatureTapped('quiet_hours', screen: 'more');
                    context.push(AppRoutes.quietHours);
                  },
                ),
              ],
            ),
          ),
          if (isFullAdmin || canManageCourses) ...[
            SizedBox(height: 18.h),
            SectionHeader(title: l10n.adminSectionTitle),
            CardContainer(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Column(
                children: [
                  if (isFullAdmin) ...[
                    NavRow(
                      icon: Icons.campaign_outlined,
                      title: l10n.adminAnnouncementsTitle,
                      onTap: () {
                        AnalyticsService.instance.logFeatureTapped('admin_announcements', screen: 'more');
                        context.push(AppRoutes.adminAnnouncements);
                      },
                    ),
                    const Divider(),
                    NavRow(
                      icon: Icons.feedback_outlined,
                      title: l10n.adminFeedbacksTitle,
                      onTap: () {
                        AnalyticsService.instance.logFeatureTapped('admin_feedbacks', screen: 'more');
                        context.push(AppRoutes.adminFeedbacks);
                      },
                    ),
                    const Divider(),
                    NavRow(
                      icon: Icons.checklist_rtl_outlined,
                      title: l10n.adminAmalFieldsTitle,
                      onTap: () {
                        AnalyticsService.instance.logFeatureTapped('admin_amal_fields', screen: 'more');
                        context.push(AppRoutes.adminAmalFields);
                      },
                    ),
                    const Divider(),
                  ],
                  if (canManageCourses) ...[
                    NavRow(
                      icon: Icons.menu_book_outlined,
                      title: l10n.adminCoursesTitle,
                      onTap: () {
                        AnalyticsService.instance.logFeatureTapped('admin_courses', screen: 'more');
                        context.push(AppRoutes.adminCourses);
                      },
                    ),
                    if (isFullAdmin) const Divider(),
                  ],
                  if (isFullAdmin) ...[
                    NavRow(
                      icon: Icons.notifications_active_outlined,
                      title: l10n.adminPushNotificationTitle,
                      onTap: () {
                        AnalyticsService.instance.logFeatureTapped('admin_push_notification', screen: 'more');
                        context.push(AppRoutes.adminPushNotification);
                      },
                    ),
                    const Divider(),
                    NavRow(
                      icon: Icons.system_update_outlined,
                      title: l10n.adminAppConfigTitle,
                      onTap: () {
                        AnalyticsService.instance.logFeatureTapped('admin_app_config', screen: 'more');
                        context.push(AppRoutes.adminAppConfigList);
                      },
                    ),
                    const Divider(),
                    NavRow(
                      icon: Icons.emoji_events_outlined,
                      title: l10n.adminKnowledgeBattleTitle,
                      onTap: () {
                        AnalyticsService.instance.logFeatureTapped('admin_knowledge_battle', screen: 'more');
                        context.push(AppRoutes.adminKnowledgeBattle);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
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
