import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/bengali_numeral_helper.dart';
import '../../../../core/utils/hijri_calendar_grid.dart';
import '../../../../core/utils/report_calculator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../hijri_calendar/presentation/widgets/hijri_cal_day_cell.dart';

class ReportCustomRangeResult {
  const ReportCustomRangeResult({
    required this.startHijri,
    required this.endHijri,
  });

  final String startHijri;
  final String endHijri;
}

Future<ReportCustomRangeResult?> showReportCustomRangePicker(
  BuildContext context, {
  String? initialStart,
  String? initialEnd,
}) {
  return showModalBottomSheet<ReportCustomRangeResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ReportCustomRangePickerSheet(
      initialStart: initialStart,
      initialEnd: initialEnd,
    ),
  );
}

class ReportCustomRangePickerSheet extends StatefulWidget {
  const ReportCustomRangePickerSheet({
    super.key,
    this.initialStart,
    this.initialEnd,
  });

  final String? initialStart;
  final String? initialEnd;

  @override
  State<ReportCustomRangePickerSheet> createState() =>
      _ReportCustomRangePickerSheetState();
}

class _ReportCustomRangePickerSheetState
    extends State<ReportCustomRangePickerSheet> {
  late int _hijriYear;
  late int _hijriMonth;
  String? _start;
  String? _end;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ym = IslamicDateService.currentHijriYearMonth();
    _hijriYear = ym.year;
    _hijriMonth = ym.month;
    _start = widget.initialStart;
    _end = widget.initialEnd;
    if (_start != null) {
      final parts = _start!.split('-');
      if (parts.length == 3) {
        _hijriYear = int.tryParse(parts[0]) ?? _hijriYear;
        _hijriMonth = int.tryParse(parts[1]) ?? _hijriMonth;
      }
    }
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
    final current = IslamicDateService.currentHijriYearMonth();
    if (_hijriYear > current.year ||
        (_hijriYear == current.year && _hijriMonth >= current.month)) {
      return;
    }
    setState(() {
      if (_hijriMonth < 12) {
        _hijriMonth++;
      } else {
        _hijriYear++;
        _hijriMonth = 1;
      }
    });
  }

  void _onDayTap(String storage) {
    final l10n = AppLocalizations.of(context)!;
    final today = IslamicDateService.getCurrentIslamicDateStringSafe();
    if (storage.compareTo(today) > 0) return;

    setState(() {
      _error = null;
      if (_start == null || (_start != null && _end != null)) {
        _start = storage;
        _end = null;
        return;
      }
      if (storage.compareTo(_start!) < 0) {
        _start = storage;
        _end = null;
        return;
      }
      final days = IslamicDateService.daysBetween(_start!, storage) + 1;
      if (days > ReportCalculator.maxCustomDays) {
        _error = l10n.reportsCustomRangeTooLong;
        return;
      }
      _end = storage;
    });
  }

  bool _isInRange(String storage) {
    if (_start == null) return false;
    if (_end == null) return storage == _start;
    return storage.compareTo(_start!) >= 0 && storage.compareTo(_end!) <= 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final today = IslamicDateService.getCurrentIslamicDateStringSafe();
    final cells = HijriCalendarGridBuilder.build(
      hijriYear: _hijriYear,
      hijriMonth: _hijriMonth,
      todayStorage: today,
    );
    final monthTitle = IslamicDateService.monthYearHeader(
      _hijriYear,
      _hijriMonth,
      languageCode: locale,
    );
    final canApply = _start != null && _end != null && _error == null;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h + bottomInset),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.emeraldDeep,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: AppColors.goldBorder),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.reportsPickRange,
                    style: AppTextStyles.headlineMedium(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 22.r,
                    color: AppColors.textSecondary,
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: Size(44.r, 44.r),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              l10n.reportsRangeHint,
              style: AppTextStyles.bodySmall(context),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: Icon(
                    Icons.chevron_left,
                    size: 24.r,
                    color: AppColors.textSecondary,
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: Size(44.r, 44.r),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                ),
                Expanded(
                  child: Text(
                    monthTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: Icon(
                    Icons.chevron_right,
                    size: 24.r,
                    color: AppColors.textSecondary,
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: Size(44.r, 44.r),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cells.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6.h,
                crossAxisSpacing: 6.w,
              ),
              itemBuilder: (context, index) {
                final cell = cells[index];
                if (cell.isEmpty || cell.hijriDay == null) {
                  return const SizedBox.shrink();
                }
                final storage = IslamicDateService.storageFromParts(
                  _hijriYear,
                  _hijriMonth,
                  cell.hijriDay!,
                );
                final isFuture = storage.compareTo(today) > 0;
                final selected = _isInRange(storage);
                final dayLabel = locale == 'bn'
                    ? toBengaliNumeral(cell.hijriDay!)
                    : '${cell.hijriDay}';

                return Opacity(
                  opacity: isFuture ? 0.35 : 1,
                  child: Material(
                    color: selected
                        ? AppColors.gold.withValues(alpha: 0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.r),
                      onTap: isFuture ? null : () => _onDayTap(storage),
                      child: HijriCalDayCell(
                        hijriDay: cell.hijriDay,
                        gregorianDay: cell.gregorianDate?.day,
                        isToday: cell.isToday,
                        hasEvent: false,
                        isEmpty: false,
                        hijriDayLabel: dayLabel,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 10.h),
            CardContainer(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Text(
                _rangeLabel(l10n, locale),
                style: AppTextStyles.bodyMedium(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: 8.h),
              Text(
                _error!,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.danger,
                ),
              ),
            ],
            SizedBox(height: 12.h),
            FilledButton(
              onPressed: canApply
                  ? () {
                      Navigator.of(context).pop(
                        ReportCustomRangeResult(
                          startHijri: _start!,
                          endHijri: _end!,
                        ),
                      );
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.emeraldDeep,
                disabledBackgroundColor: AppColors.cardBorder,
                padding: EdgeInsets.symmetric(vertical: 13.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md.r),
                ),
              ),
              child: Text(
                l10n.reportsApplyRange,
                style: AppTextStyles.button(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: canApply
                      ? AppColors.emeraldDeep
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _rangeLabel(AppLocalizations l10n, String locale) {
    if (_start == null) return l10n.reportsSelectStart;
    final startLabel = IslamicDateService.displayFromStorageEn(_start!);
    final startBn = IslamicDateService.displayFromStorageBn(_start!);
    final start = locale == 'bn' ? startBn : startLabel;
    if (_end == null) return '${l10n.reportsSelectEnd}: $start → …';
    final endLabel = locale == 'bn'
        ? IslamicDateService.displayFromStorageBn(_end!)
        : IslamicDateService.displayFromStorageEn(_end!);
    return '$start → $endLabel';
  }
}
