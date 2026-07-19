import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/default_amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/constants/amal_fields.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/report_calculator.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/report_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/streak_badge.dart';
import '../widgets/report_bar_chart.dart';
import '../widgets/report_custom_range_picker.dart';
import '../widgets/report_insights_section.dart';
import '../widgets/report_prayer_breakdown.dart';
import '../widgets/report_share_card.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriodType _type = ReportPeriodType.weekly;
  late String _startHijri;
  late String _endHijri;
  late int _monthYear;
  late int _month;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenViewed('reports');
    AnalyticsService.instance.logReportsOpened();
    AnalyticsService.instance.setLastScreen('reports');
    AnalyticsService.instance.setLastFeature('reports');
    final week = currentWeeklyRange();
    _startHijri = week.start;
    _endHijri = week.end;
    final ym = IslamicDateService.currentHijriYearMonth();
    _monthYear = ym.year;
    _month = ym.month;
  }

  void _setType(ReportPeriodType type) {
    if (_type == type) {
      if (type == ReportPeriodType.custom) {
        _openCustomPicker();
      }
      return;
    }
    AnalyticsService.instance.logReportPeriodChanged(type: type.name);
    setState(() {
      _type = type;
      switch (type) {
        case ReportPeriodType.weekly:
          final week = currentWeeklyRange();
          _startHijri = week.start;
          _endHijri = week.end;
        case ReportPeriodType.monthly:
          final ym = IslamicDateService.currentHijriYearMonth();
          _monthYear = ym.year;
          _month = ym.month;
          final range = monthlyRange(_monthYear, _month);
          _startHijri = range.start;
          _endHijri = range.end;
        case ReportPeriodType.custom:
          final week = currentWeeklyRange();
          _startHijri = week.start;
          _endHijri = week.end;
      }
    });
    if (type == ReportPeriodType.custom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openCustomPicker();
      });
    }
  }

  void _shiftPeriod(int direction) {
    setState(() {
      switch (_type) {
        case ReportPeriodType.weekly:
          _startHijri = IslamicDateService.shiftStorageByDays(
            _startHijri,
            direction * 7,
          );
          _endHijri = IslamicDateService.shiftStorageByDays(
            _endHijri,
            direction * 7,
          );
          final today = IslamicDateService.getCurrentIslamicDateStringSafe();
          if (_endHijri.compareTo(today) > 0) {
            final live = currentWeeklyRange();
            _startHijri = live.start;
            _endHijri = live.end;
          }
        case ReportPeriodType.monthly:
          if (direction < 0) {
            if (_month > 1) {
              _month--;
            } else {
              _monthYear--;
              _month = 12;
            }
          } else {
            final current = IslamicDateService.currentHijriYearMonth();
            if (_monthYear > current.year ||
                (_monthYear == current.year && _month >= current.month)) {
              return;
            }
            if (_month < 12) {
              _month++;
            } else {
              _monthYear++;
              _month = 1;
            }
          }
          final range = monthlyRange(_monthYear, _month);
          _startHijri = range.start;
          _endHijri = range.end;
        case ReportPeriodType.custom:
          break;
      }
    });
  }

  Future<void> _openCustomPicker() async {
    final result = await showReportCustomRangePicker(
      context,
      initialStart: _startHijri,
      initialEnd: _endHijri,
    );
    if (result == null || !mounted) return;
    setState(() {
      _type = ReportPeriodType.custom;
      _startHijri = result.startHijri;
      _endHijri = result.endHijri;
    });
    AnalyticsService.instance.logReportPeriodChanged(type: 'custom');
  }

  Future<void> _shareReport(ReportSummary summary) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    OverlayEntry? entry;
    try {
      final overlay = Overlay.of(context);
      final boundaryKey = GlobalKey();
      final width = MediaQuery.sizeOf(context).width;
      final l10n = AppLocalizations.of(context)!;

      entry = OverlayEntry(
        builder: (ctx) {
          return Positioned(
            left: -width * 2,
            top: 0,
            width: width,
            child: Material(
              type: MaterialType.transparency,
              child: RepaintBoundary(
                key: boundaryKey,
                child: ReportShareCard(
                  summary: summary,
                  title: _title(l10n),
                  dateMainLabel: _dateMainLabel(context),
                  dateSubLabel: _dateSubLabel(context, l10n),
                  maxScore: getMaxScore(
                    ref.read(amalFieldsListProvider),
                  ).clamp(1, kDefaultMaxDailyScore),
                  periodType: _type,
                  fields: ref.read(amalFieldsListProvider),
                ),
              ),
            ),
          );
        },
      );
      overlay.insert(entry);

      // Allow one frame for layout + image decode (app icon).
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final dpr = MediaQuery.devicePixelRatioOf(context).toDouble();
      final pixelRatio = dpr < 3.0 ? 3.0 : (dpr > 4.0 ? 4.0 : dpr);
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/amol_report_${_type.name}.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: _shareCaption(summary),
        ),
      );
      AnalyticsService.instance.logReportShared(type: _type.name);
    } catch (e, st) {
      AnalyticsService.instance.recordError(
        e,
        st,
        reason: 'Report share failed',
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportsLoadFailed)),
        );
      }
    } finally {
      entry?.remove();
      if (mounted) setState(() => _isSharing = false);
    }
  }

  String _shareCaption(ReportSummary summary) {
    final l10n = AppLocalizations.of(context)!;
    final score = summary.hasScoredLogs
        ? summary.avgScore.round().toString()
        : l10n.reportsEmDash;
    return '${_title(l10n)} · $score · ${_dateMainLabel(context)}';
  }

  String _title(AppLocalizations l10n) {
    return switch (_type) {
      ReportPeriodType.weekly => l10n.reportsWeeklyTitle,
      ReportPeriodType.monthly => l10n.reportsMonthlyTitle,
      ReportPeriodType.custom => l10n.reportsCustomTitle,
    };
  }

  String _dateMainLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (_type == ReportPeriodType.monthly) {
      return IslamicDateService.monthYearHeader(
        _monthYear,
        _month,
        languageCode: locale,
      );
    }
    final start = locale == 'bn'
        ? IslamicDateService.displayFromStorageBn(_startHijri)
        : IslamicDateService.displayFromStorageEn(_startHijri);
    final end = locale == 'bn'
        ? IslamicDateService.displayFromStorageBn(_endHijri)
        : IslamicDateService.displayFromStorageEn(_endHijri);
    if (_startHijri == _endHijri) return start;
    return '$start – $end';
  }

  String _dateSubLabel(BuildContext context, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).languageCode;
    final gregFmt = DateFormat(
      'MMM d, y',
      locale == 'bn' ? 'bn_BD' : 'en_US',
    );
    final startG = _gregorianLabel(_startHijri, gregFmt);
    final endG = _gregorianLabel(_endHijri, gregFmt);
    final range = (startG.isEmpty || endG.isEmpty)
        ? ''
        : (startG == endG ? startG : '$startG – $endG');

    final periodTag = switch (_type) {
      ReportPeriodType.weekly =>
        isLiveCurrentWeek(_startHijri, _endHijri)
            ? l10n.reportsThisWeek
            : l10n.reportsWeeklyTab,
      ReportPeriodType.monthly =>
        isLiveCurrentMonth(_startHijri, _endHijri)
            ? l10n.reportsThisMonth
            : l10n.reportsMonthlyTab,
      ReportPeriodType.custom => l10n.reportsCustomRange,
    };
    if (range.isEmpty) return periodTag;
    return '$range · $periodTag';
  }

  String _gregorianLabel(String hijri, DateFormat fmt) {
    try {
      final parts = hijri.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      final g = HijriCalendar().hijriToGregorian(y, m, d);
      return fmt.format(g);
    } catch (_) {
      return '';
    }
  }

  bool get _canGoNext {
    final today = IslamicDateService.getCurrentIslamicDateStringSafe();
    return switch (_type) {
      ReportPeriodType.weekly => _endHijri.compareTo(today) < 0,
      ReportPeriodType.monthly => !isLiveCurrentMonth(_startHijri, _endHijri),
      ReportPeriodType.custom => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authUser = ref.watch(authStateProvider).asData?.value;
    final user = ref.watch(currentUserProvider).asData?.value;

    if (authUser == null || user == null) {
      return AppScaffold(
        handleExitBack: false,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final key = ReportPeriodKey(
      uid: authUser.uid,
      type: _type,
      startHijri: _startHijri,
      endHijri: _endHijri,
    );
    final summaryAsync = ref.watch(reportSummaryProvider(key));
    final fields = ref.watch(amalFieldsListProvider);
    final maxScore = getMaxScore(fields).clamp(1, kDefaultMaxDailyScore);

    return AppScaffold(
      handleExitBack: false,
      padding: EdgeInsets.zero,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.more),
        ),
        title: Text(
          l10n.myReports,
          style: AppTextStyles.headlineMedium(context),
        ),
        actions: [
          if (summaryAsync.hasValue)
            IconButton(
              onPressed: summaryAsync.value!.logs.isEmpty || _isSharing
                  ? null
                  : () => _shareReport(summaryAsync.value!),
              icon: _isSharing
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    )
                  : Icon(Icons.ios_share, size: 20.r),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
            child: _PeriodTabs(type: _type, onChanged: _setType),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
            child: _DateNavigator(
              mainLabel: _dateMainLabel(context),
              subLabel: _dateSubLabel(context, l10n),
              canGoPrev: true,
              canGoNext: _canGoNext,
              onPrev: () => _type == ReportPeriodType.custom
                  ? _openCustomPicker()
                  : _shiftPeriod(-1),
              onNext: () => _type == ReportPeriodType.custom
                  ? _openCustomPicker()
                  : _shiftPeriod(1),
              onCenterTap: _type == ReportPeriodType.custom
                  ? _openCustomPicker
                  : null,
              customMode: _type == ReportPeriodType.custom,
            ),
          ),
          Expanded(
            child: summaryAsync.when(
              loading: () => const _ReportSkeleton(),
              error: (_, _) => Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.reportsLoadFailed,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge(context),
                      ),
                      SizedBox(height: 12.h),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(reportSummaryProvider(key)),
                        child: Text(l10n.reportsRetry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (summary) => _ReportBody(
                summary: summary,
                title: _title(l10n),
                maxScore: maxScore,
                periodType: _type,
                fields: fields,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.type, required this.onChanged});

  final ReportPeriodType type;
  final ValueChanged<ReportPeriodType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      (ReportPeriodType.weekly, l10n.reportsWeeklyTab),
      (ReportPeriodType.monthly, l10n.reportsMonthlyTab),
      (ReportPeriodType.custom, l10n.reportsCustomTab),
    ];
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          if (i > 0) SizedBox(width: 8.w),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(tabs[i].$1),
                borderRadius: BorderRadius.circular(20.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: EdgeInsets.symmetric(vertical: 9.h),
                  decoration: BoxDecoration(
                    color: type == tabs[i].$1
                        ? AppColors.gold
                        : AppColors.cardDark,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: type == tabs[i].$1
                          ? AppColors.gold
                          : AppColors.cardBorder,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i].$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: type == tabs[i].$1
                          ? AppColors.emeraldDeep
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.mainLabel,
    required this.subLabel,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.customMode,
    this.onCenterTap,
  });

  final String mainLabel;
  final String subLabel;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool customMode;
  final VoidCallback? onCenterTap;

  @override
  Widget build(BuildContext context) {
    final prevEnabled = canGoPrev || customMode;
    final nextEnabled = canGoNext || customMode;

    return Row(
      children: [
        _NavArrowButton(
          icon: customMode ? Icons.edit_calendar_outlined : Icons.chevron_left,
          enabled: prevEnabled,
          onTap: prevEnabled ? onPrev : null,
        ),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCenterTap,
              borderRadius: BorderRadius.circular(8.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: Column(
                  children: [
                    Text(
                      mainLabel,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subLabel,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _NavArrowButton(
          icon: customMode ? Icons.date_range_outlined : Icons.chevron_right,
          enabled: nextEnabled,
          onTap: nextEnabled ? onNext : null,
        ),
      ],
    );
  }
}

class _NavArrowButton extends StatelessWidget {
  const _NavArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cardDark,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(
            icon,
            size: 20.r,
            color: enabled ? AppColors.textSecondary : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.summary,
    required this.title,
    required this.maxScore,
    required this.periodType,
    required this.fields,
  });

  final ReportSummary summary;
  final String title;
  final int maxScore;
  final ReportPeriodType periodType;
  final List<AmalField> fields;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dash = l10n.reportsEmDash;
    final avg = summary.hasScoredLogs
        ? summary.avgScore.round().toString()
        : dash;
    final streakValue = summary.liveCurrentStreak ?? summary.bestStreakInPeriod;
    final streakLabel = summary.liveCurrentStreak != null
        ? l10n.reportsCurrentStreak
        : l10n.reportsBestStreak;
    final rankValue = summary.rankInfo != null
        ? '#${summary.rankInfo!.rank}'
        : dash;
    final rankSublabel = summary.rankInfo != null
        ? l10n.reportsCommunityRank
        : l10n.reportsRankUnavailable;

    final chartLabel =
        summary.eligibleDays > ReportCalculator.bucketThresholdDays
        ? l10n.reportsChartWeekly
        : l10n.reportsChartDaily;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                          CardContainer(
                            color: AppColors.goldCard,
                            borderColor: AppColors.goldBorder,
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    16.w,
                                    14.h,
                                    16.w,
                                    14.h,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title.toUpperCase(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.label(
                                                context,
                                              ).copyWith(
                                                color: AppColors.goldLight,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(height: 6.h),
                                            Pill(
                                              text: l10n.reportsDaysLogged(
                                                summary.daysLogged,
                                                summary.eligibleDays,
                                              ),
                                              color: AppColors.successLight,
                                              textColor: AppColors.success,
                                              icon: Icons.check_circle_outline,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            avg,
                                            style:
                                                AppTextStyles.goldNumeric(
                                                  context,
                                                ).copyWith(
                                                  fontSize: 28.sp,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          Text(
                                            l10n.reportsAvgScore,
                                            style: AppTextStyles.bodySmall(
                                              context,
                                            ).copyWith(fontSize: 10.sp),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: AppColors.goldBorder,
                                ),
                                IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _MiniStat(
                                          value: '$streakValue',
                                          label: streakLabel,
                                        ),
                                      ),
                                      VerticalDivider(
                                        width: 1,
                                        thickness: 0.5,
                                        color: AppColors.goldBorder,
                                      ),
                                      Expanded(
                                        child: _MiniStat(
                                          value: '${summary.consistency}%',
                                          label: l10n.reportsConsistency,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: AppColors.goldBorder,
                                ),
                                IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _MiniStat(
                                          value:
                                              summary.bestDayScore
                                                  ?.toString() ??
                                              dash,
                                          label: l10n.reportsBestDayScore,
                                        ),
                                      ),
                                      VerticalDivider(
                                        width: 1,
                                        thickness: 0.5,
                                        color: AppColors.goldBorder,
                                      ),
                                      Expanded(
                                        child: _MiniStat(
                                          value: periodType ==
                                                  ReportPeriodType.custom
                                              ? '${summary.eligibleDays}'
                                              : rankValue,
                                          label: periodType ==
                                                  ReportPeriodType.custom
                                              ? l10n.reportsDaysInRange
                                              : rankSublabel,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (summary.logs.isEmpty) ...[
                            SizedBox(height: 24.h),
                            Text(
                              l10n.reportsEmptyPeriod,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ] else ...[
                            if (summary.bars.isNotEmpty) ...[
                              SizedBox(height: 16.h),
                              SectionHeader(title: chartLabel),
                              ReportBarChart(
                                bars: summary.bars,
                                maxScore: maxScore,
                              ),
                            ],
                            if (summary.amalBreakdown.isNotEmpty) ...[
                              SizedBox(height: 16.h),
                              SectionHeader(title: l10n.reportsAmalBreakdown),
                              ReportAmalBreakdownList(
                                stats: summary.amalBreakdown,
                              ),
                              SizedBox(height: 16.h),
                              SectionHeader(title: l10n.prayerBreakdown),
                              ReportPrayerBreakdownSection(
                                logs: summary.logs,
                                fields: fields,
                              ),
                            ],
                            SizedBox(height: 16.h),
                            SectionHeader(title: l10n.reportsInsights),
                            ReportInsightsCard(summary: summary),
                            if (summary.hadithText != null &&
                                summary.hadithText!.isNotEmpty) ...[
                              SizedBox(height: 16.h),
                              SectionHeader(
                                title: l10n.reportsHadithOfPeriod,
                              ),
                              ReportHadithCard(text: summary.hadithText!),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.goldNumeric(context).copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontSize: 10.sp,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
      child: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 40.h),
        children: [
          Container(
            height: 160.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            height: 88.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          SizedBox(height: 16.h),
          for (var i = 0; i < 5; i++) ...[
            Container(
              height: 40.h,
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
