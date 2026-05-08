import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/hadith_asset_service.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/streak_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/amal_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';
import '../../../../shared/widgets/streak_freeze_modal.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  ProviderSubscription<AmalState>? _amalErrorSubscription;
  String? _listeningUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _amalErrorSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) return;
    ref.invalidate(amalProvider(uid));
  }

  void _ensureAmalErrorListener(String uid) {
    if (_listeningUid == uid) return;
    _amalErrorSubscription?.close();
    _listeningUid = uid;
    _amalErrorSubscription = ref.listenManual<AmalState>(amalProvider(uid), (
      previous,
      next,
    ) {
      if (!mounted || next.error == null || previous?.error == next.error) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(next.error!)));
    });
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

    final amal = ref.watch(amalProvider(authUser.uid));
    final amalNotifier = ref.read(amalProvider(authUser.uid).notifier);
    _ensureAmalErrorListener(authUser.uid);

    // Only show banner once we know status; [none] means offline per connectivity_plus.
    final offline =
        connectivity != null && connectivity.contains(ConnectivityResult.none);

    final displayStreak = resolveDisplayedStreakValues(
      currentStreak: user.currentStreak,
      bestStreak: user.bestStreak,
      hasSubmittedToday: amal.isSubmitted,
    );
    final isNewUser = user.lastLogDate.trim().isEmpty && !amal.isSubmitted;

    return AppScaffold(
      padding: EdgeInsets.zero,
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 96.h),
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
          if (amal.error != null) ...[
            Text(
              amal.error!,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.danger, fontSize: 12.sp),
            ),
            SizedBox(height: 8.h),
          ],
          _ProgressCard(
            done: amal.doneCount,
            total: kAmalFields.length,
            score: amal.totalScore,
          ),
          if (isNewUser) ...[SizedBox(height: 14.h), _WelcomeCard(l10n: l10n)],
          SizedBox(height: 14.h),
          if (amal.isSubmitted) ...[
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
            Text(l10n.todaysAmal, style: AppTextStyles.headlineMedium(context)),
            SizedBox(height: 6.h),
            ...kAmalFields.map(
              (f) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: f.type == AmalType.numeric
                    ? AmalRow(
                        field: f,
                        done:
                            getNumericValue(amal.toggles[f.id], f.maxValue) > 0,
                        numericValue: getNumericValue(
                          amal.toggles[f.id],
                          f.maxValue,
                        ),
                        onTapDetails: () => _showAmalDetailsDialog(context, f),
                        readOnly: true,
                      )
                    : AmalRow(
                        field: f,
                        done: amal.toggles[f.id] as bool? ?? false,
                        onTapDetails: () => _showAmalDetailsDialog(context, f),
                        readOnly: true,
                      ),
              ),
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
                  onPressed: amal.isLoading
                      ? null
                      : amal.hasAnyDone
                      ? amalNotifier.clearAll
                      : amalNotifier.markAllDone,
                  icon: Icon(
                    amal.hasAnyDone ? Icons.restart_alt : Icons.done_all,
                    size: 17.r,
                    color: amal.hasAnyDone ? AppColors.warning : AppColors.gold,
                  ),
                  label: Text(
                    amal.hasAnyDone ? l10n.deselectAll : l10n.markAllDone,
                    style: AppTextStyles.button(context).copyWith(
                      color: amal.hasAnyDone
                          ? AppColors.warning
                          : AppColors.gold,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: amal.hasAnyDone
                          ? AppColors.warning.withValues(alpha: 0.65)
                          : AppColors.goldBorder,
                    ),
                    backgroundColor: amal.hasAnyDone
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
            if (amal.isLoading)
              const _HomeAmalLoadingShimmer()
            else
              ...kAmalFields.map(
                (f) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: f.type == AmalType.numeric
                      ? AmalRow(
                          field: f,
                          done:
                              getNumericValue(amal.toggles[f.id], f.maxValue) >
                              0,
                          numericValue: getNumericValue(
                            amal.toggles[f.id],
                            f.maxValue,
                          ),
                          maxAllowed: f.id == 'takbir'
                              ? getNumericValue(amal.toggles['fard'], 5)
                              : f.maxValue,
                          onNumericChanged: (v) =>
                              amalNotifier.setNumeric(f.id, v),
                          onTapDetails: () =>
                              _showAmalDetailsDialog(context, f),
                        )
                      : AmalRow(
                          field: f,
                          done: amal.toggles[f.id] as bool? ?? false,
                          onChanged: (_) => amalNotifier.toggle(f.id),
                          onTapDetails: () =>
                              _showAmalDetailsDialog(context, f),
                        ),
                ),
              ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: amal.hasAnyDone
                  ? ElevatedButton(
                      onPressed: amal.isLoading
                          ? null
                          : () => _onSubmit(context, authUser.uid, user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.emeraldDeep,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: amal.isLoading
                          ? SizedBox(
                              width: 22.r,
                              height: 22.r,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.emeraldDeep,
                              ),
                            )
                          : Text(
                              l10n.saveTodaysAmal,
                              style: AppTextStyles.button(context).copyWith(
                                color: AppColors.emeraldDeep,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    )
                  : OutlinedButton(
                      onPressed: amal.isLoading
                          ? null
                          : amalNotifier.markAllDone,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        side: const BorderSide(color: AppColors.goldBorder),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        l10n.markAllDone,
                        style: AppTextStyles.button(context).copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 8.h),
            Text(
              amal.hasAnyDone
                  ? l10n.draftSavedTapSaveToFinish
                  : l10n.progressAutosavedHint,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textSecondary, fontSize: 12.sp),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onSubmit(
    BuildContext context,
    String uid,
    UserModel user,
  ) async {
    final notifier = ref.read(amalProvider(uid).notifier);
    final result = await notifier.submit(user);
    if (!context.mounted) return;
    if (result == null) return;

    if (result.streakResult.action == StreakAction.showFreeze) {
      await StreakFreezeModal.show(
        context,
        preservedStreak: result.streakResult.newCurrentStreak,
        onUseFreeze: () async {
          await notifier.applyFreeze(user);
          if (!context.mounted) return;
          context.push(AppRoutes.dayComplete, extra: result.log);
        },
        onResetStreak: () async {
          await notifier.resetStreak(user.uid);
          if (!context.mounted) return;
          context.push(AppRoutes.dayComplete, extra: result.log);
        },
      );
    } else {
      context.push(AppRoutes.dayComplete, extra: result.log);
    }
  }

  Future<void> _showAmalDetailsDialog(
    BuildContext context,
    AmalField field,
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
                            field.labelBn,
                            style: AppTextStyles.bodyLarge(context).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15.sp,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            field.label,
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
                    field.sublabel,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
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

class _HomeAmalLoadingShimmer extends StatelessWidget {
  const _HomeAmalLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Shimmer.fromColors(
        baseColor: AppColors.cardDark,
        highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
        child: Column(
          children: List.generate(
            kAmalFields.length,
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
                  IslamicDateService.weekdayEnglishToday(),
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
                  child: Container(
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

  const _ProgressCard({
    required this.done,
    required this.total,
    required this.score,
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
                  l10n.scoreOutOfPoints(score, kMaxDailyScore),
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
