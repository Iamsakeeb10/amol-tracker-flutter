import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/hijri_events.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/hijri_event_labels.dart';
import '../../../../core/utils/hijri_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';

class HijriEventStrip extends StatelessWidget {
  const HijriEventStrip({
    super.key,
    required this.hijriYear,
    required this.hijriMonth,
  });

  final int hijriYear;
  final int hijriMonth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final events = HijriEvents.forMonth(hijriMonth);
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.islamicEventsTitle),
        CardContainer(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Column(
            children: [
              for (var i = 0; i < events.length; i++) ...[
                if (i > 0) const Divider(),
                _EventRow(
                  title: HijriEventLabels.label(l10n, events[i].id),
                  dateLabel: _dateLabel(
                    locale: locale,
                    year: hijriYear,
                    month: hijriMonth,
                    day: events[i].day,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _dateLabel({
    required String locale,
    required int year,
    required int month,
    required int day,
  }) {
    final storage = IslamicDateService.storageFromParts(year, month, day);
    if (locale == 'bn') {
      return IslamicDateService.displayFromStorageBn(storage);
    }
    final weekday = HijriHelper.weekdayEnglishForHijriStorage(storage);
    final monthName = HijriHelper.monthYearDisplay(year, month).split(' ').first;
    return '$weekday, $day $monthName $year';
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.title, required this.dateLabel});

  final String title;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: AppColors.goldCard,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.goldBorder),
            ),
            child: Icon(
              Icons.nights_stay_outlined,
              size: 16.r,
              color: AppColors.gold,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  dateLabel,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
