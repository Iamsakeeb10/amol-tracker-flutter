import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/amal_fields.dart' as amal_const;
import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/hijri_helper.dart';
import '../../../../core/utils/streak_helper.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../providers/amal_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/history_provider.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/calendar_day_cell.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../l10n/app_localizations.dart';

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
    final now = HijriCalendar.fromDate(HijriHelper.bangladeshNow());
    _hijriYear = now.hYear;
    _hijriMonth = now.hMonth;
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
    required int daysInMonth,
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
      final key = HijriHelper.storageFromParts(_hijriYear, _hijriMonth, d);
      final cmp = key.compareTo(todayStr);

      if (cmp > 0) {
        out.add(MockDay(day: d, score: 0, state: DayCompletion.future));
        continue;
      }

      final log = byDay[d];

      if (key == todayStr) {
        out.add(
          MockDay(day: d, score: log?.score ?? 0, state: DayCompletion.today),
        );
        continue;
      }

      if (log == null) {
        out.add(MockDay(day: d, score: 0, state: DayCompletion.miss));
        continue;
      }

      final sc = log.score;
      DayCompletion st;
      if (sc >= 80) {
        st = DayCompletion.full;
      } else if (sc >= 50) {
        st = DayCompletion.partial;
      } else {
        st = DayCompletion.miss;
      }
      out.add(MockDay(day: d, score: sc, state: st));
    }
    return out;
  }

  ({String id, String label, int misses})? _weakestAmal(
    List<AmalLogModel> logs,
  ) {
    if (logs.isEmpty) return null;
    final counts = <String, int>{
      for (final f in amal_const.kAmalFields) f.id: 0,
    };
    for (final log in logs) {
      for (final f in amal_const.kAmalFields) {
        if (log.toggles[f.id] != true) {
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
    final field = amal_const.kAmalFields.firstWhere((f) => f.id == maxId);
    return (id: maxId!, label: field.label, misses: maxC);
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
    final todayStr = HijriHelper.todayString();
    final cal = HijriCalendar();
    final daysInMonth = cal.getDaysInMonth(_hijriYear, _hijriMonth);

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
            daysInMonth: daysInMonth,
          );
          final logged50 = logs.where((l) => l.score >= 50).length;
          final consistency = daysInMonth == 0
              ? 0
              : ((logged50 / daysInMonth) * 100).round();
          final avgScore = logs.isEmpty
              ? 0
              : logs.map((l) => l.score).reduce((a, b) => a + b) / logs.length;
          final weakest = _weakestAmal(logs);

          return ListView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
            children: [
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
                          HijriHelper.monthYearDisplay(_hijriYear, _hijriMonth),
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
                      value: logs.isEmpty ? '—' : avgScore.round().toString(),
                      sublabel: logs.isEmpty
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
                  mainAxisSpacing: 6.h,
                  crossAxisSpacing: 6.w,
                ),
                itemCount: days.length,
                itemBuilder: (_, i) {
                  final day = days[i];
                  return CalendarDayCell(
                    day: day,
                    onTap: () {
                      final keyDate = HijriHelper.storageFromParts(
                        _hijriYear,
                        _hijriMonth,
                        day.day,
                      );
                      if (day.state == DayCompletion.future) return;
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
              const _Legend(),
              SizedBox(height: 16.h),
              if (weakest != null)
                CardContainer(
                  color: AppColors.dangerLight,
                  borderColor: AppColors.danger.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        color: AppColors.danger,
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
          );
        },
      ),
    );
  }
}

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
              mainAxisSpacing: 6.h,
              crossAxisSpacing: 6.w,
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

class _Legend extends StatelessWidget {
  const _Legend();

  Widget _dot(Color color) => Container(
    width: 10.r,
    height: 10.r,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(AppColors.gold),
        SizedBox(width: 6.w),
        Text(
          AppLocalizations.of(context)!.historyFull,
          style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp),
        ),
        SizedBox(width: 12.w),
        _dot(AppColors.warning),
        SizedBox(width: 6.w),
        Text(
          AppLocalizations.of(context)!.historyPartial,
          style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp),
        ),
        SizedBox(width: 12.w),
        _dot(AppColors.danger),
        SizedBox(width: 6.w),
        Text(
          AppLocalizations.of(context)!.historyMiss,
          style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp),
        ),
      ],
    );
  }
}
