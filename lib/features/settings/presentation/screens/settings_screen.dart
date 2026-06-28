import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/time_display_helper.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/leaderboard_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../widget/widget_pin_service.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/toggle_row.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _showInLeaderboard = true;
  bool _anonymousDisplay = false;
  bool _ramadanMode = false;
  String? _lastSyncedUid;

  Future<void> _setAnonymous(bool value) async {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) return;
    setState(() => _anonymousDisplay = value);
    await ref
        .read(firestoreServiceProvider)
        .updateUserDisplayFields(uid, isAnonymousDisplay: value);
    ref.invalidate(dailyLeaderboardProvider);
    ref.invalidate(weeklyLeaderboardProvider);
    ref.invalidate(streakLeaderboardProvider);
  }

  Future<void> _setShowOnLeaderboard(bool value) async {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) return;
    final previous = _showInLeaderboard;
    setState(() => _showInLeaderboard = value);
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateUserDisplayFields(uid, showOnLeaderboard: value);
      ref.invalidate(dailyLeaderboardProvider);
      ref.invalidate(weeklyLeaderboardProvider);
      ref.invalidate(streakLeaderboardProvider);
    } catch (_) {
      if (mounted) {
        setState(() => _showInLeaderboard = previous);
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final l10n = AppLocalizations.of(context)!;
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOutTitle),
        content: Text(l10n.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (shouldSignOut != true) return;
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    context.go(AppRoutes.signIn);
  }

  Future<void> _showHomeWidgetSheet() async {
    final l10n = AppLocalizations.of(context)!;
    var isSubmitting = false;
    var showFallback = false;
    var statusMessage = '';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.emeraldMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isAndroid = Theme.of(ctx).platform == TargetPlatform.android;
            return Padding(
              padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 22.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeWidgetSetupTitle,
                    style: AppTextStyles.headlineMedium(ctx),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    l10n.homeWidgetSetupBody,
                    style: AppTextStyles.bodyMedium(
                      ctx,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 14.h),
                  if (isAndroid)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() {
                                  isSubmitting = true;
                                  statusMessage = '';
                                });
                                final supported =
                                    await WidgetPinService.isPinSupported();
                                if (!supported) {
                                  setModalState(() {
                                    showFallback = true;
                                    statusMessage =
                                        l10n.homeWidgetUnsupportedMessage;
                                    isSubmitting = false;
                                  });
                                  return;
                                }

                                final requested =
                                    await WidgetPinService.requestPin();
                                setModalState(() {
                                  showFallback = !requested;
                                  statusMessage = requested
                                      ? l10n.homeWidgetPinRequested
                                      : l10n.homeWidgetPinFailed;
                                  isSubmitting = false;
                                });
                              },
                        icon: Icon(Icons.add_box_outlined, size: 18.r),
                        label: Text(l10n.homeWidgetAddButton),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.emeraldDeep,
                          textStyle: AppTextStyles.button(
                            ctx,
                          ).copyWith(color: AppColors.emeraldDeep),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        l10n.homeWidgetIosGuide,
                        style: AppTextStyles.bodyMedium(ctx),
                      ),
                    ),
                  if (statusMessage.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      statusMessage,
                      style: AppTextStyles.bodySmall(
                        ctx,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  if (showFallback || !isAndroid) ...[
                    SizedBox(height: 12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.goldBorder),
                      ),
                      child: Text(
                        l10n.homeWidgetFallbackSteps,
                        style: AppTextStyles.bodySmall(ctx),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(notificationPrefsProvider);
    final prefsNotifier = ref.read(notificationPrefsProvider.notifier);
    final me = ref.watch(currentUserProvider).asData?.value;
    final locale = ref.watch(localeProvider);
    final authUid = ref.watch(authStateProvider).asData?.value?.uid;
    if (me != null && _lastSyncedUid != authUid) {
      _showInLeaderboard = me.showOnLeaderboard;
      _anonymousDisplay = me.isAnonymousDisplay;
      _lastSyncedUid = authUid;
    }
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/more'),
        ),
        title: Text(
          l10n.settings,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 4.h, 0, 24.h),
        children: [
          SectionHeader(title: l10n.notificationsSection),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            child: Column(
              children: [
                ToggleRow(
                  icon: Icons.notifications_active_outlined,
                  title: l10n.morningNotification,
                  subtitle: formatBdTime(context, prefs.morningTime),
                  value: prefs.morningEnabled,
                  onChanged: (v) => prefsNotifier.setMorningEnabled(v),
                ),
                const Divider(),
                ToggleRow(
                  icon: Icons.wb_twighlight,
                  title: l10n.eveningNotification,
                  subtitle: formatBdTime(context, prefs.eveningTime),
                  value: prefs.eveningEnabled,
                  onChanged: (v) => prefsNotifier.setEveningEnabled(v),
                ),
                const Divider(),
                InkWell(
                  onTap: () => context.pushNamed('reminderTimes'),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Row(
                      children: [
                        Container(
                          width: 34.r,
                          height: 34.r,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.cardBorder,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.schedule_outlined,
                            size: 16.r,
                            color: AppColors.gold,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            l10n.reminderTimes,
                            style: AppTextStyles.bodyLarge(
                              context,
                            ).copyWith(fontSize: 14.sp),
                          ),
                        ),
                        Text(
                          formatBdTime(context, prefs.morningTime),
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: AppColors.textMuted),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textMuted,
                          size: 18.r,
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                ToggleRow(
                  icon: Icons.local_fire_department_outlined,
                  title: l10n.streakWarning,
                  subtitle: l10n.streakWarningSubtitle,
                  value: prefs.streakEnabled,
                  onChanged: (v) => prefsNotifier.setStreakEnabled(v),
                ),
                const Divider(),
                ToggleRow(
                  icon: Icons.group_outlined,
                  title: l10n.communityActivity,
                  subtitle: l10n.communityActivitySubtitle,
                  value: prefs.communityEnabled,
                  onChanged: (v) => prefsNotifier.setCommunityEnabled(v),
                ),
                const Divider(),
                InkWell(
                  onTap: () => context.push(AppRoutes.quietHours),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Row(
                      children: [
                        Container(
                          width: 34.r,
                          height: 34.r,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.cardBorder,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.do_not_disturb_on_outlined,
                            size: 16.r,
                            color: AppColors.gold,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            l10n.quietHours,
                            style: AppTextStyles.bodyLarge(
                              context,
                            ).copyWith(fontSize: 14.sp),
                          ),
                        ),
                        Text(
                          '${formatBdTime(context, prefs.quietFrom)} — ${formatBdTime(context, prefs.quietTo)}',
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: AppColors.textMuted),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textMuted,
                          size: 18.r,
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.graphic_eq_outlined,
                  title: l10n.prayerAdhanReminder,
                  onTap: () => context.push(AppRoutes.prayerAdhan),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SectionHeader(title: l10n.privacySection),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            child: Column(
              children: [
                ToggleRow(
                  icon: Icons.leaderboard_outlined,
                  title: l10n.showOnLeaderboard,
                  value: me?.showOnLeaderboard ?? _showInLeaderboard,
                  onChanged: _setShowOnLeaderboard,
                ),
                const Divider(),
                ToggleRow(
                  icon: Icons.visibility_outlined,
                  title: l10n.showAnonymous,
                  subtitle: l10n.showAnonymousSubtitle,
                  value: me?.isAnonymousDisplay ?? _anonymousDisplay,
                  onChanged: _setAnonymous,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SectionHeader(title: l10n.languageSection),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.language_outlined, size: 20.r),
                  title: Text(
                    l10n.english,
                    style: AppTextStyles.bodyLarge(context),
                  ),
                  trailing: Icon(
                    locale.languageCode == 'en'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: locale.languageCode == 'en'
                        ? AppColors.gold
                        : AppColors.textMuted,
                  ),
                  onTap: () => ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('en')),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.language_outlined, size: 20.r),
                  title: Text(
                    l10n.bangla,
                    style: AppTextStyles.bodyLarge(context),
                  ),
                  trailing: Icon(
                    locale.languageCode == 'bn'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: locale.languageCode == 'bn'
                        ? AppColors.gold
                        : AppColors.textMuted,
                  ),
                  onTap: () => ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('bn')),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SectionHeader(title: l10n.appSection),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            child: Column(
              children: [
                NavRow(
                  icon: Icons.calendar_view_month_outlined,
                  title: l10n.calendarType,
                  trailing: l10n.hijri,
                  onTap: () => context.push(AppRoutes.hijriCalendar),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.widgets_outlined,
                  title: l10n.homeWidgetSettingsTitle,
                  trailing: l10n.homeWidgetSettingsSubtitle,
                  onTap: _showHomeWidgetSheet,
                ),
                const Divider(),
                ToggleRow(
                  icon: Icons.brightness_2_outlined,
                  title: l10n.ramadanMode,
                  subtitle: l10n.ramadanModeSubtitle,
                  value: _ramadanMode,
                  onChanged: (v) => setState(() => _ramadanMode = v),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.description_outlined,
                  title: l10n.termsAndConditions,
                  onTap: () => launchUrl(Uri.parse('https://iamsakeeb10.github.io/amol-tracker-legal/terms_conditions.html')),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.privacyPolicy,
                  onTap: () => launchUrl(Uri.parse('https://iamsakeeb10.github.io/amol-tracker-legal/privacy_policy.html')),
                ),
                const Divider(),
                NavRow(
                  icon: Icons.logout_rounded,
                  title: l10n.signOut,
                  destructiveColor: AppColors.danger,
                  onTap: _confirmSignOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
