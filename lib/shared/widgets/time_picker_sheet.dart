import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

/// Fully custom 12-hour bottom sheet time picker.
/// No dependency on MediaQuery.alwaysUse24HourFormat - always 12h.
Future<TimeOfDay?> showBdTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      top: false,
      child: _BdTimePickerSheet(initialTime: initialTime),
    ),
  );
}

class _BdTimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;
  const _BdTimePickerSheet({required this.initialTime});

  @override
  State<_BdTimePickerSheet> createState() => _BdTimePickerSheetState();
}

class _BdTimePickerSheetState extends State<_BdTimePickerSheet> {
  late int _hour; // 1-12
  late int _minute; // 0-59
  late bool _isAm;

  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTime;
    _isAm = t.period == DayPeriod.am;
    _hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    _minute = t.minute;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour - 1);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  TimeOfDay get _result {
    var hour24 = _hour % 12;
    if (!_isAm) hour24 += 12;
    return TimeOfDay(hour: hour24, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.emeraldMid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(top: BorderSide(color: AppColors.goldBorder, width: 1.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Select Time',
            style:
                AppTextStyles.headlineMedium(context).copyWith(color: AppColors.gold),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 180.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ScrollColumn(
                  controller: _hourCtrl,
                  itemCount: 12,
                  labelBuilder: (i) => '${i + 1}'.padLeft(2, '0'),
                  onChanged: (i) => setState(() => _hour = i + 1),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text(
                    ':',
                    style: AppTextStyles.displayLarge(
                      context,
                    ).copyWith(color: AppColors.gold, fontSize: 32.sp),
                  ),
                ),
                _ScrollColumn(
                  controller: _minuteCtrl,
                  itemCount: 60,
                  labelBuilder: (i) => '$i'.padLeft(2, '0'),
                  onChanged: (i) => setState(() => _minute = i),
                ),
                SizedBox(width: 20.w),
                _AmPmToggle(
                  isAm: _isAm,
                  onChanged: (v) => setState(() => _isAm = v),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _result),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScrollColumn extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int) labelBuilder;
  final ValueChanged<int> onChanged;

  const _ScrollColumn({
    required this.controller,
    required this.itemCount,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.goldCard,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.goldBorder),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 48.h,
            perspective: 0.003,
            diameterRatio: 1.6,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (context, index) => Center(
                child: Text(
                  labelBuilder(index),
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmPmToggle extends StatelessWidget {
  final bool isAm;
  final ValueChanged<bool> onChanged;

  const _AmPmToggle({required this.isAm, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Pill(label: 'AM', selected: isAm, onTap: () => onChanged(true)),
        SizedBox(height: 8.h),
        _Pill(label: 'PM', selected: !isAm, onTap: () => onChanged(false)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.cardBorder,
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.emeraldDeep : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
