import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/constants/default_amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/hadith_asset_service.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../../core/utils/streak_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../models/announcement_model.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../providers/amal_provider.dart';
import '../../../../providers/announcement_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/history_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../shared/widgets/amal_fields_list_section.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/announcement_modal.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<String> _sessionDismissedAnnouncementIds = <String>{};
  bool _isAnnouncementDialogOpen = false;

  Future<void> _showAnnouncementDialog(AnnouncementModel announcement) async {
    if (!mounted || _isAnnouncementDialogOpen) return;
    if (_sessionDismissedAnnouncementIds.contains(announcement.id)) return;

    _isAnnouncementDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (_) => AnnouncementModal(announcement: announcement),
    );

    if (!mounted) return;
    _isAnnouncementDialogOpen = false;
    if (!announcement.showOnce) {
      setState(() {
        _sessionDismissedAnnouncementIds.add(announcement.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authUser = ref.watch(authStateProvider).asData?.value;
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;
    final connectivity = ref.watch(connectivityListProvider).asData?.value;

    if (authUser == null || user == null) {
      return AppScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final uid = authUser.uid;
    final amalNotifier = ref.read(amalProvider(uid).notifier);
    final fieldsAsync = ref.watch(amalFieldsProvider);
    final fields = ref.watch(amalFieldsListProvider);
    final locale = Localizations.localeOf(context).languageCode;
    final maxScore = getMaxScore(fields).clamp(1, kDefaultMaxDailyScore);
    final doneCount = ref.watch(amalProvider(uid).select((s) => s.doneCount));
    final totalScore = ref.watch(amalProvider(uid).select((s) => s.totalScore));
    final isSubmitted = ref.watch(
      amalProvider(uid).select((s) => s.isSubmitted),
    );
    final isAmalLoading = ref.watch(
      amalProvider(uid).select((s) => s.isLoading),
    );
    final hasAnyDone = ref.watch(amalProvider(uid).select((s) => s.hasAnyDone));
    final amalError = ref.watch(amalProvider(uid).select((s) => s.error));
    ref.listen(amalProvider(uid).select((s) => s.error), (previous, next) {
      if (!mounted || next == null || previous == next) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
    });
    ref.listen<AnnouncementModel?>(pendingAnnouncementProvider, (
      previous,
      next,
    ) {
      if (next == null) return;
      if (previous?.id == next.id) return;
      if (_sessionDismissedAnnouncementIds.contains(next.id)) return;

      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _showAnnouncementDialog(next);
      });
    });

    // Only show banner once we know status; [none] means offline per connectivity_plus.
    final offline =
        connectivity != null && connectivity.contains(ConnectivityResult.none);

    final displayStreak = resolveDisplayedStreakValues(
      currentStreak: user.currentStreak,
      bestStreak: user.bestStreak,
      hasSubmittedToday: isSubmitted,
    );
    final isNewUser = user.lastLogDate.trim().isEmpty && !isSubmitted;
    final todayHijri = IslamicDateService.getCurrentIslamicDateStringSafe();
    final submittedLog = ref.watch(
      amalProvider(uid).select((s) => s.submittedLog),
    );
    ref.watch(amalLogRefreshProvider);

    final showSaveFab = !isSubmitted && hasAnyDone;

    return AppScaffold(
      padding: EdgeInsets.zero,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20.w,
          8.h,
          20.w,
          showSaveFab ? 112.h : 96.h,
        ),
        children: [
          if (offline)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: CardContainer(
                color: AppColors.warningLight.withValues(alpha: 0.35),
                borderColor: AppColors.warning.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: AppColors.warning, size: 18.r),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        l10n.homeOfflineSyncMessage,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _Header(displayName: user.name, streak: displayStreak.currentStreak),
          // SizedBox(height: 18.h),
          SizedBox(height: 14.h),
          if (amalError != null) ...[
            Text(
              amalError,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.danger, fontSize: 12.sp),
            ),
            SizedBox(height: 8.h),
          ],
          _ProgressCard(
            done: doneCount,
            total: fields.length,
            score: totalScore,
            maxScore: maxScore,
          ),
          if (isNewUser) ...[SizedBox(height: 14.h), _WelcomeCard(l10n: l10n)],
          SizedBox(height: 14.h),
          if (isSubmitted) ...[
            CardContainer.gold(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 22.r,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      l10n.loggedToday,
                      style: AppTextStyles.bodyLarge(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.todaysAmal,
                    style: AppTextStyles.headlineMedium(context),
                  ),
                ),
                _SubmittedAmalIconButton(
                  icon: Icons.check_circle,
                  tooltip: l10n.markAllDone,
                  iconColor: AppColors.success,
                ),
                SizedBox(width: 8.w),
                _SubmittedAmalIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: l10n.editTodayAmal,
                  onPressed: submittedLog == null
                      ? null
                      : () => _onEditTodayAmal(
                          context,
                          uid: uid,
                          todayHijri: todayHijri,
                          log: submittedLog,
                        ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ..._buildAmalFieldSection(
              uid: uid,
              fieldsAsync: fieldsAsync,
              fields: fields,
              locale: locale,
              readOnly: true,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.todaysAmal,
                    style: AppTextStyles.headlineMedium(context),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: isAmalLoading
                      ? null
                      : hasAnyDone
                      ? amalNotifier.clearAll
                      : amalNotifier.markAllDone,
                  icon: Icon(
                    hasAnyDone ? Icons.restart_alt : Icons.done_all,
                    size: 17.r,
                    color: hasAnyDone ? AppColors.warning : AppColors.gold,
                  ),
                  label: Text(
                    hasAnyDone ? l10n.deselectAll : l10n.markAllDone,
                    style: AppTextStyles.button(context).copyWith(
                      color: hasAnyDone ? AppColors.warning : AppColors.gold,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: hasAnyDone
                          ? AppColors.warning.withValues(alpha: 0.65)
                          : AppColors.goldBorder,
                    ),
                    backgroundColor: hasAnyDone
                        ? AppColors.warningLight
                        : AppColors.goldCard,
                    foregroundColor: AppColors.gold,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    minimumSize: Size(0, 40.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            if (isAmalLoading || fieldsAsync.isLoading)
              const _HomeAmalLoadingShimmer()
            else
              ..._buildAmalFieldSection(
                uid: uid,
                fieldsAsync: fieldsAsync,
                fields: fields,
                locale: locale,
              ),
            SizedBox(height: 14.h),
            Text(
              hasAnyDone
                  ? l10n.draftSavedTapSaveToFinish
                  : l10n.progressAutosavedHint,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textSecondary, fontSize: 12.sp),
            ),
          ],
          SizedBox(height: 14.h),
          CardContainer(
            onTap: () => context.push(AppRoutes.dhikr),
            child: Row(
              children: [
                Container(
                  width: 42.r,
                  height: 42.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.goldCard,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.goldBorder),
                  ),
                  child: Icon(
                    Icons.fiber_manual_record_outlined,
                    color: AppColors.gold,
                    size: 20.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dhikrCounter,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        l10n.dhikrShortcutSubtitle,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20.r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onEditTodayAmal(
    BuildContext context, {
    required String uid,
    required String todayHijri,
    required AmalLogModel log,
  }) async {
    await context.push(AppRoutes.editAmalPath(todayHijri), extra: log);
    if (!mounted) return;
    ref.invalidate(amalProvider(uid));
  }

  List<Widget> _buildAmalFieldSection({
    required String uid,
    required AsyncValue<List<AmalField>> fieldsAsync,
    required List<AmalField> fields,
    required String locale,
    bool readOnly = false,
  }) {
    return fieldsAsync.when(
      loading: () => [const _HomeAmalLoadingShimmer()],
      error: (_, __) => [
        _AmalFieldsStatusCard(
          message: locale == 'bn'
              ? 'আমল লোড করতে সমস্যা হয়েছে'
              : 'Failed to load amal fields',
          showRetry: true,
          onRetry: () async {
            await ref.read(amalFieldsProvider.notifier).forceRefresh();
            if (!mounted) return;
            await ref.read(amalProvider(uid).notifier).refreshFromFields();
          },
        ),
      ],
      data: (loadedFields) => [
        AmalFieldsListSection(
          uid: uid,
          fields: loadedFields,
          locale: locale,
          readOnly: readOnly,
          onTapDetails: (f) => _showAmalDetailsDialog(context, f, locale),
        ),
      ],
    );
  }

  Future<void> _showAmalDetailsDialog(
    BuildContext context,
    AmalField field,
    String locale,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
          child: CardContainer(
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 14.h),
            borderColor: AppColors.goldBorder.withValues(alpha: 0.8),
            color: AppColors.emeraldMid.withValues(alpha: 0.98),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24.r,
                offset: Offset(0, 10.h),
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42.r,
                      height: 42.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.goldCard,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.goldBorder),
                      ),
                      child: Icon(
                        amalFieldIcon(field.id),
                        color: AppColors.gold,
                        size: 22.r,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            field.getLabel(locale),
                            style: AppTextStyles.bodyLarge(context).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15.sp,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            field.getLabel(locale == 'bn' ? 'en' : 'bn'),
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                        size: 20.r,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldDeep.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.goldBorder.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    field.getSublabel(locale),
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textPrimary, height: 1.35),
                  ),
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _DetailChip(
                      icon: Icons.workspace_premium_outlined,
                      text: '+${field.points} pts',
                    ),
                    _DetailChip(
                      icon: field.type == AmalType.numeric
                          ? Icons.pin_outlined
                          : Icons.toggle_on_outlined,
                      text: field.type == AmalType.numeric
                          ? 'Target: ${field.maxValue}'
                          : 'Type: Toggle',
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.goldBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 11.h),
                    ),
                    child: Text(
                      l10n.cancel,
                      style: AppTextStyles.button(context).copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubmittedAmalIconButton extends StatelessWidget {
  const _SubmittedAmalIconButton({
    required this.icon,
    required this.tooltip,
    this.iconColor = AppColors.gold,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color iconColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: 40.r,
            height: 40.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.goldCard,
              border: Border.all(color: AppColors.goldBorder),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: iconColor, size: 20.r),
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.goldCard,
        borderRadius: BorderRadius.circular(99.r),
        border: Border.all(color: AppColors.goldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 14.r),
          SizedBox(width: 6.w),
          Text(
            text,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmalFieldsStatusCard extends StatelessWidget {
  const _AmalFieldsStatusCard({
    required this.message,
    this.showRetry = false,
    this.onRetry,
  });

  final String message;
  final bool showRetry;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      color: AppColors.warningLight.withValues(alpha: 0.25),
      borderColor: AppColors.warning.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppTextStyles.bodyMedium(context)),
          if (showRetry && onRetry != null) ...[
            SizedBox(height: 10.h),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

class _HomeAmalLoadingShimmer extends StatelessWidget {
  const _HomeAmalLoadingShimmer({this.rowCount = 9});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Shimmer.fromColors(
        baseColor: AppColors.cardDark,
        highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
        child: Column(
          children: List.generate(
            rowCount,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Container(
                height: 56.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return CardContainer.gold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.goldLight, size: 16.r),
              SizedBox(width: 6.w),
              Text(
                l10n.welcomeUpper,
                style: AppTextStyles.label(
                  context,
                ).copyWith(color: AppColors.gold),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.firstAmalStartsToday,
            style: AppTextStyles.bodyLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6.h),
          FutureBuilder<List<String>>(
            future: HadithAssetService.loadHadithTexts(),
            builder: (context, snapshot) {
              final hadiths = snapshot.data ?? const <String>[];
              final hadith = hadiths.isEmpty ? null : hadiths.first;
              if (hadith == null) return const SizedBox.shrink();
              return Text(hadith, style: AppTextStyles.bodyMedium(context));
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.displayName, required this.streak});

  final String displayName;
  final int streak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final unread = ref.watch(unreadNotificationsCountProvider);
    final unreadLabel = unread > 99 ? '99+' : '$unread';

    return GestureDetector(
      onTap: () => context.push(AppRoutes.history),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            IslamicDateService.getDisplayIslamicDate(),
            style: AppTextStyles.label(context).copyWith(color: AppColors.gold),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  IslamicDateService.weekdayToday(languageCode: locale),
                  style: AppTextStyles.displayMedium(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              InkWell(
                onTap: () => context.push(AppRoutes.profile),
                borderRadius: BorderRadius.circular(99.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldCard,
                    border: Border.all(color: AppColors.goldBorder),
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: AppColors.warning,
                        size: 15.r,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        l10n.dayStreak(streak),
                        style: AppTextStyles.pill(
                          context,
                        ).copyWith(color: AppColors.gold, fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              InkWell(
                onTap: () => context.push(AppRoutes.notifications),
                borderRadius: BorderRadius.circular(12.r),
                child: Tooltip(
                  message: l10n.notifications,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 34.r,
                        height: 34.r,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.goldCard,
                          border: Border.all(color: AppColors.goldBorder),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.gold,
                          size: 20.r,
                        ),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -5.w,
                          top: -5.h,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(99.r),
                              border: Border.all(
                                color: AppColors.emeraldDeep,
                                width: 1.w,
                              ),
                            ),
                            constraints: BoxConstraints(minWidth: 16.r),
                            child: Text(
                              unreadLabel,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.pill(context).copyWith(
                                color: AppColors.emeraldDeep,
                                fontWeight: FontWeight.w700,
                                fontSize: 9.sp,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int done;
  final int total;
  final int score;
  final int maxScore;

  const _ProgressCard({
    required this.done,
    required this.total,
    required this.score,
    required this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.todaysProgress,
                  style: AppTextStyles.bodyMedium(context),
                ),
              ),
              Text(
                '$done/$total',
                style: AppTextStyles.goldNumeric(
                  context,
                ).copyWith(fontSize: 18.sp),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ScoreBar(value: total == 0 ? 0 : done / total),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.gold,
                size: 14.r,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  l10n.scoreOutOfPoints(score, maxScore),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
