import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/amal_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../core/utils/streak_helper.dart';
import '../../../../shared/mock/mock_data.dart' show kHadiths;
import '../../../../shared/widgets/streak_freeze_modal.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';
import '../../../../l10n/app_localizations.dart';

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
          _Header(displayName: user.name),
          SizedBox(height: 18.h),
          _StreakBanner(
            streak: displayStreak.currentStreak,
            bestStreak: displayStreak.bestStreak,
            onTap: () => context.push(AppRoutes.history),
          ),
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
                        readOnly: true,
                      )
                    : AmalRow(
                        field: f,
                        done: amal.toggles[f.id] as bool? ?? false,
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
                TextButton(
                  onPressed: amal.isLoading ? null : amalNotifier.markAllDone,
                  child: Text(
                    l10n.markAllDone,
                    style: AppTextStyles.button(
                      context,
                    ).copyWith(color: AppColors.gold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            if (amal.isLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              )
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
                        )
                      : AmalRow(
                          field: f,
                          done: amal.toggles[f.id] as bool? ?? false,
                          onChanged: (_) => amalNotifier.toggle(f.id),
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
                              l10n.submitTodaysLog,
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
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final hadith = kHadiths.first;
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
          Text(hadith, style: AppTextStyles.bodyMedium(context)),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trimmed = displayName.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.substring(0, 1).toUpperCase();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.push(AppRoutes.history),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      IslamicDateService.getDisplayIslamicDate(),
                      style: AppTextStyles.label(
                        context,
                      ).copyWith(color: AppColors.gold),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      IslamicDateService.weekdayEnglishToday(),
                      style: AppTextStyles.displayMedium(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AvatarChip(
          initial: initial,
          color: AppColors.gold,
          ring: true,
          size: 38,
          fontSize: 16,
        ),
      ],
    );
  }
}

class _StreakBanner extends StatelessWidget {
  final int streak;
  final int bestStreak;
  final VoidCallback onTap;

  const _StreakBanner({
    required this.streak,
    required this.bestStreak,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: CardContainer.gold(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.local_fire_department,
                color: AppColors.warning,
                size: 22.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.dayStreak(streak),
                          style: AppTextStyles.bodyLarge(
                            context,
                          ).copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(99.r),
                        ),
                        child: Text(
                          l10n.onFire,
                          style: AppTextStyles.pill(
                            context,
                          ).copyWith(color: AppColors.warning, fontSize: 10.sp),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    l10n.bestStreakKeepGoing(bestStreak),
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(fontSize: 11.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
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
