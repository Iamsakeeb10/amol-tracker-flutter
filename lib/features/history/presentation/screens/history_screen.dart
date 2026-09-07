import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/personal_amol_month_calculator.dart';
import '../../../../core/utils/streak_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../models/personal_amol_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/history_provider.dart';
import '../../../../providers/personal_amol_provider.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/calendar_day_cell.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late int _hijriYear;
  late int _hijriMonth;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenViewed('history');
    final ym = IslamicDateService.currentHijriYearMonth();
    _hijriYear = ym.year;
    _hijriMonth = ym.month;
  }

  void _prevMonth() {
    setState(() {
      if (_hijriMonth > 1) {
        _hijriMonth--;
      } else {
        _hijriYear--;
        _hijriMonth = 12;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_hijriMonth < 12) {
        _hijriMonth++;
      } else {
        _hijriYear++;
        _hijriMonth = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authUser = ref.watch(authStateProvider).asData?.value;
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;

    if (authUser == null || user == null) {
      return AppScaffold(
        handleExitBack: false,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final locale = Localizations.localeOf(context).languageCode;
    ref.watch(amalLogRefreshProvider);

    return AppScaffold(
      handleExitBack: false,
      padding: EdgeInsets.zero,
      body: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.history,
                          style: AppTextStyles.label(
                            context,
                          ).copyWith(color: AppColors.gold),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          IslamicDateService.monthYearHeader(
                            _hijriYear,
                            _hijriMonth,
                            languageCode: locale,
                          ),
                          style: AppTextStyles.displayMedium(context),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _prevMonth,
                    icon: Icon(
                      Icons.chevron_left,
                      color: AppColors.textSecondary,
                      size: 24.r,
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                      size: 24.r,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                padding: EdgeInsets.all(2.r),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(AppRadius.md.r),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: AppColors.goldCard,
                    borderRadius: BorderRadius.circular((AppRadius.md - 2).r),
                    border: Border.all(color: AppColors.goldBorder),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  splashBorderRadius: BorderRadius.circular(AppRadius.md.r),
                  labelColor: AppColors.goldLight,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: AppTextStyles.bodySmall(context),
                  tabs: [
                    Tab(text: l10n.historyTabCommunityAmol, height: 40.h),
                    Tab(text: l10n.historyTabPersonalAmol, height: 40.h),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Expanded(
              child: TabBarView(
                children: [
                  _CommunityHistoryTab(
                    uid: authUser.uid,
                    accountCreatedAt: user.createdAt,
                    hijriYear: _hijriYear,
                    hijriMonth: _hijriMonth,
                    locale: locale,
                  ),
                  _PersonalAmolHistoryTab(
                    uid: authUser.uid,
                    accountCreatedAt: user.createdAt,
                    hijriYear: _hijriYear,
                    hijriMonth: _hijriMonth,
                    locale: locale,
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

// ── Community Tab ───────────────────────────────────────────────────────────

class _CommunityHistoryTab extends ConsumerWidget {
  const _CommunityHistoryTab({
    required this.uid,
    required this.accountCreatedAt,
    required this.hijriYear,
    required this.hijriMonth,
    required this.locale,
  });

  final String uid;
  final DateTime accountCreatedAt;
  final int hijriYear;
  final int hijriMonth;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;
    final liveStreak = ref.watch(liveStreakProvider).value ?? user?.currentStreak ?? 0;
    final displayStreak = DisplayStreakValues(
      currentStreak: liveStreak,
      bestStreak: (user?.bestStreak ?? 0) < liveStreak
          ? liveStreak
          : (user?.bestStreak ?? 0),
    );
    final key = HistoryMonthKey(
      uid: uid,
      hijriYear: hijriYear,
      hijriMonth: hijriMonth,
    );
    final summaryAsync = ref.watch(
      historyMonthSummaryProvider(
        HistoryMonthSummaryInput(
          monthKey: key,
          accountCreatedAt: accountCreatedAt,
          locale: locale,
        ),
      ),
    );
    final daysInMonth = HijriCalendar().getDaysInMonth(hijriYear, hijriMonth);

    return summaryAsync.when(
      loading: () => const _HistorySkeleton(),
      error: (_, _) => Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Text(
            l10n.historyLoadFailed,
            style: AppTextStyles.bodyLarge(context),
          ),
        ),
      ),
      data: (summary) {
        final days = summary.days;
        final consistency = summary.consistency;
        final avgScore = summary.avgScore;
        final weakest = summary.weakestAmal;
        final logs = summary.logs;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.historyConsistency(consistency),
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: AppColors.gold),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: l10n.historyLoggedDays,
                            value: '${logs.length}',
                            sublabel: l10n.historyOfDays(daysInMonth),
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: StatCard(
                            label: l10n.historyAvgScore,
                            value: summary.hasScoredLogs
                                ? avgScore.round().toString()
                                : '—',
                            sublabel: summary.hasScoredLogs
                                ? l10n.historyThisMonth
                                : l10n.historyNoLogsYet,
                            icon: Icons.analytics_outlined,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    StatCard(
                      label: l10n.historyBestStreak,
                      value: '${displayStreak.bestStreak}',
                      sublabel: l10n.historyDays,
                      icon: Icons.local_fire_department_outlined,
                    ),
                    SizedBox(height: 16.h),
                    if (logs.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Text(
                          l10n.historyStartLogging,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: AppColors.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8.h,
                  crossAxisSpacing: 8.w,
                ),
                itemCount: days.length,
                itemBuilder: (_, i) {
                  final day = days[i];
                  return CalendarDayCell(
                    day: day,
                    onTap: () {
                      if (day.state == DayCompletion.future) return;
                      if (day.state == DayCompletion.preAccount) return;
                      final keyDate = IslamicDateService.storageFromParts(
                        hijriYear,
                        hijriMonth,
                        day.day,
                      );
                      context.push(AppRoutes.dayDetailPath(keyDate));
                    },
                  );
                },
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (days.any((d) => d.state == DayCompletion.preAccount))
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: CardContainer(
                          color: AppColors.cardDark,
                          borderColor: AppColors.cardBorder,
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16.r,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Dim dates are from before your account was created.',
                                  style: AppTextStyles.bodySmall(
                                    context,
                                  ).copyWith(color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const _Legend(),
                    SizedBox(height: 16.h),
                    if (logs.isNotEmpty)
                      _buildMotivationalTip(context, days, logs),
                    if (weakest != null) ...[
                      SizedBox(height: 12.h),
                      CardContainer(
                        color: AppColors.warningLight,
                        borderColor: AppColors.warning.withValues(alpha: 0.3),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tips_and_updates_outlined,
                              color: AppColors.warning,
                              size: 18.r,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.historyWeakestAmal,
                                    style: AppTextStyles.bodyLarge(context)
                                        .copyWith(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    l10n.historyWeakestAmalDetail(
                                      weakest.label,
                                      weakest.misses,
                                    ),
                                    style: AppTextStyles.bodySmall(context)
                                        .copyWith(fontSize: 11.sp),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Shows a gentle, encouraging card based on the month's activity.
  Widget _buildMotivationalTip(
    BuildContext context,
    List<MockDay> days,
    List<AmalLogModel> logs,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final fullDays = days.where((d) => d.state == DayCompletion.full).length;
    final partialDays = days
        .where((d) => d.state == DayCompletion.partial)
        .length;
    final lightDays = days.where((d) => d.state == DayCompletion.light).length;
    final minimalDays = days
        .where((d) => d.state == DayCompletion.minimal)
        .length;
    final noDataDays = days
        .where(
          (d) =>
              d.state != DayCompletion.preAccount &&
              d.state != DayCompletion.future &&
              d.state != DayCompletion.today &&
              d.state == DayCompletion.noData,
        )
        .length;

    String message;
    Color cardColor;
    Color borderColor;
    IconData icon;

    if (fullDays >= 5) {
      message = l10n.historyMotivationFull(fullDays);
      cardColor = AppColors.successLight;
      borderColor = AppColors.success.withValues(alpha: 0.3);
      icon = Icons.favorite_outline_rounded;
    } else if (partialDays + lightDays >= 3) {
      message = l10n.historyMotivationPartial;
      cardColor = AppColors.goldCard;
      borderColor = AppColors.goldBorder;
      icon = Icons.emoji_events_outlined;
    } else if (minimalDays >= 2) {
      message = l10n.historyMotivationMinimal;
      cardColor = AppColors.cardDark;
      borderColor = AppColors.cardBorder;
      icon = Icons.water_drop_outlined;
    } else if (noDataDays > 5) {
      message = l10n.historyMotivationNoData;
      cardColor = AppColors.cardDark;
      borderColor = AppColors.cardBorder;
      icon = Icons.refresh_rounded;
    } else {
      message = l10n.historyMotivationDefault;
      cardColor = AppColors.cardDark;
      borderColor = AppColors.cardBorder;
      icon = Icons.auto_awesome_outlined;
    }

    return CardContainer(
      color: cardColor,
      borderColor: borderColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold, size: 18.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(fontSize: 12.sp, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Personal Amol Tab ───────────────────────────────────────────────────────

class _PersonalAmolHistoryTab extends ConsumerWidget {
  const _PersonalAmolHistoryTab({
    required this.uid,
    required this.accountCreatedAt,
    required this.hijriYear,
    required this.hijriMonth,
    required this.locale,
  });

  final String uid;
  final DateTime accountCreatedAt;
  final int hijriYear;
  final int hijriMonth;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final amols = ref.watch(activePersonalAmolProvider(uid)).value ??
        const <PersonalAmolModel>[];
    final key = PersonalAmolMonthKey(
      uid: uid,
      hijriYear: hijriYear,
      hijriMonth: hijriMonth,
    );
    final completionsAsync = ref.watch(
      personalAmolMonthCompletionSummaryProvider(key),
    );
    final daysInMonth = HijriCalendar().getDaysInMonth(hijriYear, hijriMonth);
    final todayStr = IslamicDateService.getCurrentIslamicDateStringSafe();
    final accountCreatedHijri =
        IslamicDateService.hijriStorageForAccountCreated(accountCreatedAt);

    return completionsAsync.when(
      loading: () => const _HistorySkeleton(),
      error: (_, _) => Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Text(
            l10n.historyLoadFailed,
            style: AppTextStyles.bodyLarge(context),
          ),
        ),
      ),
      data: (completionsByDay) {
        if (amols.isEmpty) {
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildEmptyState(context),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                sliver: SliverToBoxAdapter(child: const _Legend()),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 100.h)),
            ],
          );
        }

        final days = PersonalAmolMonthCalculator.buildMonth(
          completionsByDay: completionsByDay,
          activeCount: amols.length,
          hijriYear: hijriYear,
          hijriMonth: hijriMonth,
          todayStr: todayStr,
          accountCreatedHijri: accountCreatedHijri,
          daysInMonth: daysInMonth,
        );
        final loggedDays = completionsByDay.values
            .where((count) => count > 0)
            .length;
        final totalCompletions =
            completionsByDay.values.fold<int>(0, (sum, c) => sum + c);
        final bestStreak = _maxBestStreak(ref, uid, amols, loggedDays > 0);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: l10n.historyLoggedDays,
                            value: '$loggedDays',
                            sublabel: l10n.historyOfDays(daysInMonth),
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: StatCard(
                            label: l10n.personalAmolHistoryTotalLabel,
                            value: '$totalCompletions',
                            sublabel: l10n.historyThisMonth,
                            icon: Icons.checklist_rtl_outlined,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    StatCard(
                      label: l10n.historyBestStreak,
                      value: '$bestStreak',
                      sublabel: l10n.historyDays,
                      icon: Icons.local_fire_department_outlined,
                    ),
                    SizedBox(height: 16.h),
                    if (loggedDays == 0)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        child: Text(
                          l10n.historyStartLogging,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: AppColors.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8.h,
                  crossAxisSpacing: 8.w,
                ),
                itemCount: days.length,
                itemBuilder: (_, i) {
                  final day = days[i];
                  return CalendarDayCell(
                    day: day,
                    onTap: () {
                      if (day.state == DayCompletion.future) return;
                      if (day.state == DayCompletion.preAccount) return;
                      final keyDate = IslamicDateService.storageFromParts(
                        hijriYear,
                        hijriMonth,
                        day.day,
                      );
                      context.push(AppRoutes.dayDetailPath(keyDate));
                    },
                  );
                },
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (days.any((d) => d.state == DayCompletion.preAccount))
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: CardContainer(
                          color: AppColors.cardDark,
                          borderColor: AppColors.cardBorder,
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16.r,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Dim dates are from before your account was created.',
                                  style: AppTextStyles.bodySmall(
                                    context,
                                  ).copyWith(color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const _Legend(),
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Text(
          l10n.personalAmolEmptyHeadline,
          style: AppTextStyles.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          l10n.personalAmolEmptySubtitle,
          style: AppTextStyles.label(context).copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          child: Material(
            color: AppColors.goldCard,
            borderRadius: BorderRadius.circular(20.r),
            child: InkWell(
              onTap: () => context.push(AppRoutes.personalAmolList),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.goldBorder),
                ),
                child: Text(
                  l10n.personalAmolEmptyCta,
                  style: AppTextStyles.pill(context).copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF412402),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _maxBestStreak(
    WidgetRef ref,
    String uid,
    List<PersonalAmolModel> amols,
    bool hasCompletions,
  ) {
    // With no recorded completion in view there is no streak to report; don't
    // surface a stale stored best-streak from a previously removed completion.
    if (!hasCompletions) return 0;
    var maxStreak = 0;
    for (final amol in amols) {
      final best = ref
              .watch(
                personalAmolStreakProvider(
                  PersonalAmolStreakKey(uid: uid, amolId: amol.id),
                ),
              )
              .value
              ?.bestStreak ??
          0;
      if (best > maxStreak) maxStreak = best;
    }
    return maxStreak;
  }
}

// ── Legend ──────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  Widget _dot(Color color) => Container(
    width: 10.r,
    height: 10.r,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 12.w,
      runSpacing: 6.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _legendItem(_dot(AppColors.gold), l10n.historyFull), // ≥ 80
        _legendItem(_dot(AppColors.warning), l10n.historyPartial), // 50–79
        _legendItem(
          // 20–49
          Container(
            width: 10.r,
            height: 10.r,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          l10n.historyLight, // "Light"
        ),
        _legendItem(
          // 1–19
          Container(
            width: 10.r,
            height: 10.r,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          l10n.historyMinimal, // "Minimal"
        ),
        _legendItem(
          // 0 logged
          Container(
            width: 10.r,
            height: 10.r,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.textMuted, width: 1),
              shape: BoxShape.circle,
            ),
          ),
          l10n.historyMiss,
        ),
      ],
    );
  }

  Widget _legendItem(Widget dot, String label) {
    return Builder(
      builder: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          SizedBox(width: 6.w),
          Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ────────────────────────────────────────────────────────────────

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
      child: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
        children: [
          Row(
            children: [
              Expanded(
                child: Container(height: 72.h, color: Colors.white),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Container(height: 72.h, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10.h,
              crossAxisSpacing: 10.w,
            ),
            itemCount: 35,
            itemBuilder: (context, _) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}