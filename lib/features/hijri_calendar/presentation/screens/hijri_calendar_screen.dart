import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/bengali_numeral_helper.dart';
import '../../../../core/utils/hijri_calendar_grid.dart';
import '../../../../core/utils/hijri_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../widgets/hijri_cal_day_cell.dart';
import '../widgets/hijri_event_strip.dart';

class HijriCalendarScreen extends ConsumerStatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  ConsumerState<HijriCalendarScreen> createState() =>
      _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends ConsumerState<HijriCalendarScreen> {
  late int _hijriYear;
  late int _hijriMonth;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenViewed('hijri_calendar');
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
    final locale = Localizations.localeOf(context);
    final todayStorage = IslamicDateService.getCurrentIslamicDateStringSafe();
    final cells = HijriCalendarGridBuilder.build(
      hijriYear: _hijriYear,
      hijriMonth: _hijriMonth,
      todayStorage: todayStorage,
    );
    final monthTitle = locale.languageCode == 'bn'
        ? IslamicDateService.monthYearHeader(_hijriYear, _hijriMonth)
        : HijriHelper.monthYearDisplay(_hijriYear, _hijriMonth);

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.more),
        ),
        title: Text(
          l10n.hijriCalendar,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
            sliver: SliverToBoxAdapter(
              child: _TodayHeaderCard(localeTag: locale.toLanguageTag()),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
            sliver: SliverToBoxAdapter(
              child: _MonthNavigator(
                title: monthTitle,
                onPrev: _prevMonth,
                onNext: _nextMonth,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
            sliver: SliverToBoxAdapter(
              child: _WeekdayLabels(localeTag: locale.toLanguageTag()),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 6.w,
                childAspectRatio: 1,
              ),
              itemCount: cells.length,
              itemBuilder: (_, index) {
                final cell = cells[index];
                final isBn = locale.languageCode == 'bn';
                return HijriCalDayCell(
                  hijriDay: cell.hijriDay,
                  gregorianDay: cell.gregorianDate?.day,
                  isToday: cell.isToday,
                  hasEvent: cell.hasEvent,
                  isEmpty: cell.isEmpty,
                  hijriDayLabel: cell.hijriDay == null
                      ? null
                      : isBn
                      ? toBengaliNumeral(cell.hijriDay!)
                      : '${cell.hijriDay}',
                );
              },
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
            sliver: SliverToBoxAdapter(
              child: HijriEventStrip(
                hijriYear: _hijriYear,
                hijriMonth: _hijriMonth,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayHeaderCard extends StatelessWidget {
  const _TodayHeaderCard({required this.localeTag});

  final String localeTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isBn = locale.languageCode == 'bn';
    final hijriLine = isBn
        ? IslamicDateService.getDisplayIslamicDate()
        : _englishHijriToday();
    final gregorianLine = DateFormat.yMMMEd(
      localeTag,
    ).format(IslamicDateService.nowInBD());

    return CardContainer.gold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.todayLabel,
            style: AppTextStyles.label(context).copyWith(color: AppColors.gold),
          ),
          SizedBox(height: 6.h),
          Text(
            hijriLine,
            style: AppTextStyles.displayMedium(
              context,
            ).copyWith(color: AppColors.goldPale),
          ),
          SizedBox(height: 4.h),
          Text(
            gregorianLine,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  String _englishHijriToday() {
    final storage = IslamicDateService.getCurrentIslamicDateStringSafe();
    final weekday = HijriHelper.weekdayEnglishForHijriStorage(storage);
    final parts = storage.split('-');
    if (parts.length != 3) return storage;
    final y = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 1;
    final d = int.tryParse(parts[2]) ?? 1;
    final cal = HijriCalendar();
    final greg = cal.hijriToGregorian(y, m, d);
    final h = HijriCalendar.fromDate(greg);
    return '$weekday, ${h.hDay} ${h.longMonthName} ${h.hYear}';
  }
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.title,
    required this.onPrev,
    required this.onNext,
  });

  final String title;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: Icon(Icons.chevron_left, color: AppColors.gold, size: 26.r),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium(context),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(Icons.chevron_right, color: AppColors.gold, size: 26.r),
        ),
      ],
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels({required this.localeTag});

  final String localeTag;

  @override
  Widget build(BuildContext context) {
    final labels = List.generate(7, (index) {
      final date = DateTime(2024, 1, 7 + index);
      return DateFormat('E', localeTag).format(date);
    });

    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Text(
                label,
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
