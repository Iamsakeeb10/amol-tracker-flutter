import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/toggle_row.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dailyReminder = true;
  bool _streakWarning = true;
  bool _friendActivity = false;
  bool _showInLeaderboard = true;
  bool _publicProfile = true;
  bool _ramadanMode = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/more'),
        ),
        title: Text('Settings', style: AppTextStyles.headlineMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
        children: [
          const SectionHeader(title: 'NOTIFICATIONS'),
          CardContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                ToggleRow(
                  icon: Icons.alarm,
                  title: 'Daily reminder',
                  subtitle: '08:00 each morning',
                  value: _dailyReminder,
                  onChanged: (v) => setState(() => _dailyReminder = v),
                ),
                const Divider(),
                ToggleRow(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Streak warning',
                  subtitle: 'When you risk losing your streak',
                  value: _streakWarning,
                  onChanged: (v) => setState(() => _streakWarning = v),
                ),
                const Divider(),
                ToggleRow(
                  icon: Icons.group_outlined,
                  title: 'Friend activity',
                  subtitle: 'When friends complete amal',
                  value: _friendActivity,
                  onChanged: (v) => setState(() => _friendActivity = v),
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
          const SizedBox(height: 16),
          const SectionHeader(title: 'PRIVACY'),
          CardContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                  title: 'Public profile',
                  subtitle: 'Friends can see your stats',
                  value: _publicProfile,
                  onChanged: (v) => setState(() => _publicProfile = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'APP'),
          CardContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                  subtitle: 'Adjust schedule and reminders',
                  value: _ramadanMode,
                  onChanged: (v) => setState(() => _ramadanMode = v),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  destructiveColor: AppColors.danger,
                  onTap: () => context.go(AppRoutes.signIn),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
