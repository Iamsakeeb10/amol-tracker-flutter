import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/amal_fields.dart' as amal_const;
import '../../../../core/router/routes.dart';
import '../../../../core/constants/default_amal_fields.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/streak_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../providers/amal_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/history_provider.dart';
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

  List<MockDay> _buildDays({
    required List<AmalLogModel> logs,
    required String todayStr,
    required String accountCreatedHijri,
    required int daysInMonth,
    required int maxScore,
  }) {
    final byDay = <int, AmalLogModel>{};

    for (final log in logs) {
      final segs = log.hijriDate.split('-');
      if (segs.length == 3 &&
          int.parse(segs[0]) == _hijriYear &&
          int.parse(segs[1]) == _hijriMonth) {
        final d = int.parse(segs[2]);
        byDay[d] = log;
      }
    }

    final out = <MockDay>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final key = IslamicDateService.storageFromParts(
        _hijriYear,
        _hijriMonth,
        d,
      );

      // Before account creation — show as blank, no interaction
      if (key.compareTo(accountCreatedHijri) < 0) {
        out.add(MockDay(day: d, score: 0, state: DayCompletion.preAccount));
        continue;
      }

      final cmp = key.compareTo(todayStr);

      // Future days — locked
      if (cmp > 0) {
        out.add(MockDay(day: d, score: 0, state: DayCompletion.future));
        continue;
      }

      final log = byDay[d];

      // Today
      if (key == todayStr) {
        final score = log?.score ?? 0;
        DayCompletion todayState = DayCompletion.today;
        if (log != null) {
          todayState = _scoreToState(score, hasLog: true, maxScore: maxScore);
        }
        out.add(
          MockDay(
            day: d,
            score: score,
            state: todayState,
            isEdited: log?.editedAt != null,
          ),
        );
        continue;
      }

      // Past day — no log means noData (not a failure)
      if (log == null) {
        out.add(MockDay(day: d, score: 0, state: DayCompletion.noData));
        continue;
      }

      // Past day with a log — classify by score
      final sc = log.score;
      out.add(
        MockDay(
          day: d,
          score: sc,
          state: _scoreToState(sc, hasLog: true, maxScore: maxScore),
          isEdited: log.editedAt != null,
        ),
      );
    }

    return out;
  }

  /// Maps a score to the appropriate [DayCompletion] tier.
  /// Never returns [DayCompletion.miss] for logged days — we use
  /// [DayCompletion.minimal] at worst so users are never shamed with red.
  DayCompletion _scoreToState(
    int score, {
    required bool hasLog,
    required int maxScore,
  }) {
    if (!hasLog) return DayCompletion.noData;
    final full = (maxScore * 0.8).round();
    final partial = (maxScore * 0.5).round();
    final light = (maxScore * 0.2).round();
    if (score >= full) return DayCompletion.full;
    if (score >= partial) return DayCompletion.partial;
    if (score >= light) return DayCompletion.light;
    if (score >= 1) return DayCompletion.minimal;
    return DayCompletion.miss;
  }

  /// Consistency = days at or above 50% of max score / active past days.
  int _calcConsistency({
    required List<MockDay> days,
    required List<AmalLogModel> logs,
    required int maxScore,
  }) {
    // Active days = days that are not preAccount, future, or today (today is in progress)
    final activePastDays = days
        .where(
          (d) =>
              d.state != DayCompletion.preAccount &&
              d.state != DayCompletion.future &&
              d.state != DayCompletion.today &&
              d.state !=
                  DayCompletion.noData, // noData days don't count against user
        )
        .length;

    if (activePastDays == 0) return 0;

    final halfScore = (maxScore * 0.5).round();
    final logged50Plus = logs.where((l) => l.score >= halfScore).length;
    return ((logged50Plus / activePastDays) * 100).round().clamp(0, 100);
  }

  ({String id, String label, int misses})? _weakestAmal(
    List<AmalLogModel> logs,
    List<amal_const.AmalField> fields,
    String locale,
  ) {
    if (logs.isEmpty || fields.isEmpty) return null;
    final counts = <String, int>{for (final f in fields) f.id: 0};
    for (final log in logs) {
      for (final f in fields) {
        final isDone = f.type == amal_const.AmalType.numeric
            ? getNumericValue(log.toggles[f.id], f.maxValue) > 0
            : (log.toggles[f.id] == true);
        if (!isDone) {
          counts[f.id] = (counts[f.id] ?? 0) + 1;
        }
      }
    }
    String? maxId;
    var maxC = -1;
    counts.forEach((id, c) {
      if (c > maxC) {
        maxC = c;
        maxId = id;
      }
    });
    if (maxId == null || maxC <= 0) return null;
    final field = fields.firstWhere((f) => f.id == maxId);
    return (id: maxId!, label: field.getLabel(locale), misses: maxC);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authUser = ref.watch(authStateProvider).asData?.value;
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;

    if (authUser == null || user == null) {
      return AppScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final key = HistoryMonthKey(
      uid: authUser.uid,
      hijriYear: _hijriYear,
      hijriMonth: _hijriMonth,
    );
    final amal = ref.watch(amalProvider(authUser.uid));
    final displayStreak = resolveDisplayedStreakValues(
      currentStreak: user.currentStreak,
      bestStreak: user.bestStreak,
      hasSubmittedToday: amal.isSubmitted,
    );
    final monthAsync = ref.watch(historyMonthProvider(key));
    final fields = ref.watch(amalFieldsListProvider);
    final maxScore = getMaxScore(fields).clamp(1, kDefaultMaxDailyScore);
    final locale = Localizations.localeOf(context).languageCode;
    final todayStr = IslamicDateService.getCurrentIslamicDateStringSafe();
    final accountCreatedHijri =
        IslamicDateService.islamicDateStringForGregorianDate(
          user.createdAt.toLocal(),
        );
    final daysInMonth = HijriCalendar().getDaysInMonth(_hijriYear, _hijriMonth);

    return AppScaffold(
      padding: EdgeInsets.zero,
      body: monthAsync.when(
        loading: () => _HistorySkeleton(),
        error: (_, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Text(
              l10n.historyLoadFailed,
              style: AppTextStyles.bodyLarge(context),
            ),
          ),
        ),
        data: (logs) {
          final days = _buildDays(
            logs: logs,
            todayStr: todayStr,
            accountCreatedHijri: accountCreatedHijri,
            daysInMonth: daysInMonth,
            maxScore: maxScore,
          );

          final consistency = _calcConsistency(
            days: days,
            logs: logs,
            maxScore: maxScore,
          );

          // Average score counts only days where a log exists
          final logsWithScore = logs.where((l) => l.score > 0).toList();
          final avgScore = logsWithScore.isEmpty
              ? 0.0
              : logsWithScore.map((l) => l.score).reduce((a, b) => a + b) /
                    logsWithScore.length;

          final weakest = _weakestAmal(logs, fields, locale);

          return ListView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
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
                          IslamicDateService.monthYearHeaderBn(
                            _hijriYear,
                            _hijriMonth,
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
              SizedBox(height: 6.h),

              // ── Consistency subtitle ─────────────────────────────────
              Text(
                l10n.historyConsistency(consistency),
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.gold),
              ),
              SizedBox(height: 16.h),

              // ── Stat cards ───────────────────────────────────────────
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
                      value: logsWithScore.isEmpty
                          ? '—'
                          : avgScore.round().toString(),
                      sublabel: logsWithScore.isEmpty
                          ? l10n.historyNoLogsYet
                          : l10n.historyThisMonth,
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

              // ── Calendar ─────────────────────────────────────────────
              const _DayLabels(),
              SizedBox(height: 8.h),
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                      final keyDate = IslamicDateService.storageFromParts(
                        _hijriYear,
                        _hijriMonth,
                        day.day,
                      );
                      if (day.state == DayCompletion.future) return;
                      if (day.state == DayCompletion.preAccount) return;
                      if (keyDate == todayStr) {
                        context.go(AppRoutes.home);
                        return;
                      }
                      context.push(AppRoutes.dayDetailPath(keyDate));
                    },
                  );
                },
              ),
              SizedBox(height: 12.h),

              // ── Pre-account notice ───────────────────────────────────
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

              // ── Legend ───────────────────────────────────────────────
              const _Legend(),
              SizedBox(height: 16.h),

              // ── Motivational tip ─────────────────────────────────────
              if (logs.isNotEmpty) _buildMotivationalTip(context, days, logs),

              // ── Weakest amal ─────────────────────────────────────────
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
                              style: AppTextStyles.bodyLarge(context).copyWith(
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
              ],
            ],
          );
        },
      ),
    );
  }

  /// Shows a gentle, encouraging card based on the month's activity.
  Widget _buildMotivationalTip(
    BuildContext context,
    List<MockDay> days,
    List<AmalLogModel> logs,
  ) {
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
      message =
          'মাশাআল্লাহ! আপনি এই মাসে $fullDays দিন পূর্ণ আমল করেছেন। আল্লাহ কবুল করুন।';
      cardColor = AppColors.successLight;
      borderColor = AppColors.success.withValues(alpha: 0.3);
      icon = Icons.favorite_outline_rounded;
    } else if (partialDays + lightDays >= 3) {
      message =
          'আপনি নিয়মিত চেষ্টা করছেন — এটাই সবচেয়ে গুরুত্বপূর্ণ। ধীরে ধীরে আরও বাড়বে ইনশাআল্লাহ।';
      cardColor = AppColors.goldCard;
      borderColor = AppColors.goldBorder;
      icon = Icons.emoji_events_outlined;
    } else if (minimalDays >= 2) {
      message =
          'প্রতিটি ছোট আমলও আল্লাহর কাছে মূল্যবান। আজকে একটু বেশি করার চেষ্টা করুন।';
      cardColor = AppColors.cardDark;
      borderColor = AppColors.cardBorder;
      icon = Icons.water_drop_outlined;
    } else if (noDataDays > 5) {
      message =
          'কিছু দিন লগ করা হয়নি — কোনো সমস্যা নেই। আজ থেকে আবার শুরু করুন, আল্লাহ ক্ষমাশীল।';
      cardColor = AppColors.cardDark;
      borderColor = AppColors.cardBorder;
      icon = Icons.refresh_rounded;
    } else {
      message = 'প্রতিদিন আমল লগ করুন — ছোট হলেও নিয়মিত আমলই সর্বোত্তম।';
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

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _HistorySkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
      child: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
        children: [
          Container(height: 28.h, width: 180.w, color: Colors.white),
          SizedBox(height: 16.h),
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

// ── Day Labels ────────────────────────────────────────────────────────────────

class _DayLabels extends StatelessWidget {
  const _DayLabels();

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _labels
          .map(
            (l) => Expanded(
              child: Text(
                l,
                textAlign: TextAlign.center,
                style: AppTextStyles.label(
                  context,
                ).copyWith(color: AppColors.textMuted),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────

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
          'হালকা', // "Light"
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
          'সামান্য', // "Minimal"
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
