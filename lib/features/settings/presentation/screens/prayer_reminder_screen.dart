import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/prayer_adhan_constants.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/prayer_adhan_offset_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../providers/prayer_adhan_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/time_picker_sheet.dart';
import '../widgets/prayer_reminder_row.dart';

class PrayerReminderScreen extends ConsumerWidget {
  const PrayerReminderScreen({super.key});

  String _prayerLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'fajr':
        return l10n.prayerFajr;
      case 'dhuhr':
        return l10n.prayerDhuhr;
      case 'asr':
        return l10n.prayerAsr;
      case 'maghrib':
        return l10n.prayerMaghrib;
      case 'isha':
        return l10n.prayerIsha;
      default:
        return key;
    }
  }

  Future<void> _pickPrayerTime(
    BuildContext context,
    WidgetRef ref,
    String prayer,
  ) async {
    final notifier = ref.read(prayerAdhanProvider.notifier);
    final selected = await showBdTimePicker(
      context: context,
      initialTime: notifier.baseTimeToday(prayer),
    );
    if (selected == null) return;
    await notifier.setCustomTime(prayer, selected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(prayerAdhanProvider);
    // Rebuild when quiet hours change so suppression labels stay accurate.
    ref.watch(
      notificationPrefsProvider.select((prefs) => (prefs.quietFrom, prefs.quietTo)),
    );
    final notifier = ref.read(prayerAdhanProvider.notifier);
    final times = IslamicDateService.getPrayerTimesForToday();
    final locale = Localizations.localeOf(context).toString();

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.settings),
        ),
        title: Text(
          l10n.prayerAdhanScreenTitle,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 8.h, 0, 24.h),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              l10n.prayerAdhanDescription,
              style: AppTextStyles.bodyMedium(context),
            ),
          ),
          SizedBox(height: 14.h),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
            child: Row(
              children: PrayerAdhanConstants.prayerKeys.map((key) {
                return Expanded(
                  child: PrayerTimesStripColumn(
                    icon: PrayerAdhanConstants.prayerIcons[key]!,
                    label: _prayerLabel(l10n, key),
                    time: DateFormat('h:mm a', locale).format(
                      times.forPrayer(key),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 12.h),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Column(
              children: [
                for (var i = 0; i < PrayerAdhanConstants.prayerKeys.length; i++)
                  ...[
                    if (i > 0) const Divider(),
                    Builder(
                      builder: (context) {
                        final key = PrayerAdhanConstants.prayerKeys[i];
                        final usesCustom = state.usesCustomTime[key] ?? false;
                        return PrayerReminderRow(
                          icon: PrayerAdhanConstants.prayerIcons[key]!,
                          title: _prayerLabel(l10n, key),
                          reminderTime: notifier.reminderTimeToday(key),
                          enabled: state.enabled[key] ?? false,
                          usesCustomTime: usesCustom,
                          isSaving: state.savingPrayers.contains(key),
                          suppressedByQuietHours:
                              notifier.isReminderSuppressedToday(key),
                          quietHoursLabel: l10n.quietHoursActive,
                          onToggle: (v) => notifier.setEnabled(key, v),
                          onPickTime: () => _pickPrayerTime(context, ref, key),
                          onReset: usesCustom
                              ? () => notifier.clearCustomTime(key)
                              : null,
                        );
                      },
                    ),
                  ],
              ],
            ),
          ),
          SizedBox(height: 12.h),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.prayerAdhanOffsetTitle,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: PrayerAdhanConstants.offsetOptions.map((offset) {
                    final selected = state.offsetMinutes == offset;
                    final isLast =
                        offset == PrayerAdhanConstants.offsetOptions.last;
                    return PrayerAdhanOffsetChip(
                      label: prayerAdhanOffsetChipLabel(
                        l10n,
                        offset,
                        languageCode:
                            Localizations.localeOf(context).languageCode,
                      ),
                      selected: selected,
                      isLast: isLast,
                      onTap: () => notifier.setOffset(offset),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
