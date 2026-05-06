import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/toggle_row.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _showInLeaderboard = true;
  bool _anonymousDisplay = false;
  bool _ramadanMode = false;

  Future<void> _setAnonymous(bool value) async {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) return;
    setState(() => _anonymousDisplay = value);
    await ref.read(firestoreServiceProvider).updateUser(uid, <String, dynamic>{
      'isAnonymousDisplay': value,
    });
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (shouldSignOut != true) return;
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    context.go(AppRoutes.signIn);
  }

  Future<void> _runMinuteNotificationTest() async {
    await NotificationService.instance.scheduleEveryMinuteForTesting(
      totalMinutes: 10,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scheduled notification test for next 10 minutes'),
      ),
    );
  }

  Future<void> _cancelMinuteNotificationTest() async {
    await NotificationService.instance.cancelEveryMinuteTesting();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cancelled minute notification test')),
    );
  }

  Future<void> _showInstantDebugNotification() async {
    await NotificationService.instance.showDebugNotificationNow();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sent instant debug notification')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(notificationPrefsProvider);
    final prefsNotifier = ref.read(notificationPrefsProvider.notifier);
    final me = ref.watch(currentUserProvider).asData?.value;
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/more'),
        ),
        title: Text('Settings', style: AppTextStyles.headlineMedium(context)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 4.h, 0, 24.h),
        children: [
          const SectionHeader(title: 'NOTIFICATIONS'),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            child: Column(
              children: [
                ToggleRow(
                  icon: Icons.notifications_active_outlined,
                  title: 'Morning notification',
                  subtitle: '06:00 each morning',
                  value: prefs.morningEnabled,
                  onChanged: (v) => prefsNotifier.setMorningEnabled(v),
                ),
                const Divider(),
                ToggleRow(
                  icon: Icons.wb_twighlight,
                  title: 'Evening notification',
                  subtitle: '06:30 each evening',
                  value: prefs.eveningEnabled,
                  onChanged: (v) => prefsNotifier.setEveningEnabled(v),
                ),
                const Divider(),
                ToggleRow(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Streak warning',
                  subtitle: 'When you risk losing your streak',
                  value: prefs.streakEnabled,
                  onChanged: (v) => prefsNotifier.setStreakEnabled(v),
                ),
                const Divider(),
                ToggleRow(
                  icon: Icons.group_outlined,
                  title: 'Community activity',
                  subtitle: 'Push updates from community',
                  value: prefs.communityEnabled,
                  onChanged: (v) => prefsNotifier.setCommunityEnabled(v),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.do_not_disturb_on_outlined,
                  title: 'Quiet hours',
                  trailing: prefsNotifier.quietHoursLabel,
                  onTap: () => context.push(AppRoutes.quietHours),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          const SectionHeader(title: 'PRIVACY'),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            child: Column(
              children: [
                ToggleRow(
                  icon: Icons.leaderboard_outlined,
                  title: 'Show me on leaderboard',
                  value: _showInLeaderboard,
                  onChanged: (v) => setState(() => _showInLeaderboard = v),
                ),
                const Divider(),
                ToggleRow(
                  icon: Icons.visibility_outlined,
                  title: 'Show as anonymous in community',
                  subtitle: 'Hide your real name and photo',
                  value: me?.isAnonymousDisplay ?? _anonymousDisplay,
                  onChanged: _setAnonymous,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          const SectionHeader(title: 'APP'),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            child: Column(
              children: [
                NavRow(
                  icon: Icons.calendar_view_month_outlined,
                  title: 'Calendar type',
                  trailing: 'Hijri',
                  onTap: () {},
                ),
                const Divider(),
                ToggleRow(
                  icon: Icons.brightness_2_outlined,
                  title: 'Ramadan mode',
                  subtitle: 'Adjust schedule and notifications',
                  value: _ramadanMode,
                  onChanged: (v) => setState(() => _ramadanMode = v),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  destructiveColor: AppColors.danger,
                  onTap: _confirmSignOut,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          const SectionHeader(title: 'DEBUG'),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            child: Column(
              children: [
                NavRow(
                  icon: Icons.notification_add_outlined,
                  title: 'Send instant debug notification',
                  onTap: _showInstantDebugNotification,
                ),
                const Divider(),
                NavRow(
                  icon: Icons.bug_report_outlined,
                  title: 'Start 1-minute notification test',
                  trailing: '10m',
                  onTap: _runMinuteNotificationTest,
                ),
                const Divider(),
                NavRow(
                  icon: Icons.stop_circle_outlined,
                  title: 'Cancel 1-minute notification test',
                  onTap: _cancelMinuteNotificationTest,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
