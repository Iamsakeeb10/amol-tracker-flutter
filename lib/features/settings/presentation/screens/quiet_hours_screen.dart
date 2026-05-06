import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';

class QuietHoursScreen extends ConsumerStatefulWidget {
  const QuietHoursScreen({super.key});

  @override
  ConsumerState<QuietHoursScreen> createState() => _QuietHoursScreenState();
}

class _QuietHoursScreenState extends ConsumerState<QuietHoursScreen> {
  TimeOfDay _from = const TimeOfDay(hour: 21, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 6, minute: 0);

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(notificationPrefsProvider);
    _from = prefs.quietFrom;
    _to = prefs.quietTo;
  }

  String _format(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void _bumpHour(TimeOfDay t, int delta, bool start) {
    final newHour = (t.hour + delta) % 24;
    final v = TimeOfDay(
      hour: newHour < 0 ? newHour + 24 : newHour,
      minute: t.minute,
    );
    setState(() {
      if (start) {
        _from = v;
      } else {
        _to = v;
      }
    });
  }

  String _silenceHoursLabel() {
    final fromMinutes = _from.hour * 60 + _from.minute;
    final toMinutes = _to.hour * 60 + _to.minute;
    var duration = toMinutes - fromMinutes;
    if (duration <= 0) duration += 24 * 60;
    final hours = duration ~/ 60;
    final mins = duration % 60;
    if (mins == 0) return '$hours hours of silence';
    return '$hours h $mins m of silence';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/settings'),
        ),
        title: Text(
          'Quiet hours',
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 8.h, 0, 24.h),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Notifications stay silent during these hours. Notification schedules still run.',
              style: AppTextStyles.bodyMedium(context),
            ),
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _TimeCard(
                  label: 'FROM',
                  time: _from,
                  formatted: _format(_from),
                  onUp: () => _bumpHour(_from, 1, true),
                  onDown: () => _bumpHour(_from, -1, true),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _TimeCard(
                  label: 'TO',
                  time: _to,
                  formatted: _format(_to),
                  onUp: () => _bumpHour(_to, 1, false),
                  onDown: () => _bumpHour(_to, -1, false),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          CardContainer(
            child: Row(
              children: [
                Icon(Icons.nightlight_round, color: AppColors.gold, size: 20.r),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Silent from ${_format(_from)} to ${_format(_to)}',
                    style: AppTextStyles.bodyLarge(
                      context,
                    ).copyWith(fontSize: 13.sp),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              _silenceHoursLabel(),
              style: AppTextStyles.bodySmall(context),
            ),
          ),
          SizedBox(height: 18.h),
          SizedBox(
            height: 50.h,
            child: ElevatedButton(
              onPressed: () async {
                await ref
                    .read(notificationPrefsProvider.notifier)
                    .setQuietHours(from: _from, to: _to);
                if (!context.mounted) return;
                context.canPop() ? context.pop() : context.go('/settings');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.emeraldDeep,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'Save',
                style: AppTextStyles.button(context).copyWith(
                  color: AppColors.emeraldDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final String formatted;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const _TimeCard({
    required this.label,
    required this.time,
    required this.formatted,
    required this.onUp,
    required this.onDown,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: EdgeInsets.symmetric(vertical: 18.h),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.label(context).copyWith(color: AppColors.gold),
          ),
          SizedBox(height: 8.h),
          Text(
            formatted,
            style: AppTextStyles.displayLarge(
              context,
            ).copyWith(color: AppColors.goldLight, fontSize: 36.sp),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onDown,
                icon: Icon(Icons.remove, size: 20.r),
                color: AppColors.gold,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: const CircleBorder(),
                ),
              ),
              SizedBox(width: 10.w),
              IconButton(
                onPressed: onUp,
                icon: Icon(Icons.add, size: 20.r),
                color: AppColors.gold,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
