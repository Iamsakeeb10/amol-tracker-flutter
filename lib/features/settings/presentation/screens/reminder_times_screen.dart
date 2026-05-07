import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/toggle_row.dart';
import '../../../../l10n/app_localizations.dart';

class ReminderTimesScreen extends ConsumerWidget {
  const ReminderTimesScreen({super.key});

  Future<void> _pickMorningTime(
    BuildContext context,
    WidgetRef ref,
    NotificationPrefsState prefs,
  ) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: prefs.morningTime,
    );
    if (selected == null) return;
    await ref.read(notificationPrefsProvider.notifier).setMorningTime(selected);
  }

  Future<void> _pickEveningTime(
    BuildContext context,
    WidgetRef ref,
    NotificationPrefsState prefs,
  ) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: prefs.eveningTime,
    );
    if (selected == null) return;
    await ref.read(notificationPrefsProvider.notifier).setEveningTime(selected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(notificationPrefsProvider);
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.settings),
        ),
        title: Text(
          l10n.reminderTimes,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 8.h, 0, 24.h),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              l10n.reminderTimesDescription,
              style: AppTextStyles.bodyMedium(context),
            ),
          ),
          SizedBox(height: 14.h),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Column(
              children: [
                NavRow(
                  icon: Icons.alarm_outlined,
                  title: l10n.morningNotificationTimeLabel,
                  trailing: prefs.morningTime.format(context),
                  onTap: () => _pickMorningTime(context, ref, prefs),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.nights_stay_outlined,
                  title: l10n.eveningNotificationTimeLabel,
                  trailing: prefs.eveningTime.format(context),
                  onTap: () => _pickEveningTime(context, ref, prefs),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
