import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/calendar_day_cell.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final days = buildMockMonth();
    final completed =
        days.where((d) => d.state == DayCompletion.full).length;
    final consistency = ((completed / days.length) * 100).round();
    return AppScaffold(
      padding: EdgeInsets.zero,
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HISTORY',
                      style: AppTextStyles.label(context).copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text('Shawwal 1447', style: AppTextStyles.displayMedium(context)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.chevron_left,
                  color: AppColors.textSecondary,
                  size: 24.r,
                ),
              ),
              IconButton(
                onPressed: () {},
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
            '$consistency% consistency',
            style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.gold),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Completed',
                  value: '$completed',
                  sublabel: 'of ${days.length} days',
                  icon: Icons.check_circle_outline,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: StatCard(
                  label: 'Best streak',
                  value: '${kCurrentUser.bestStreak}',
                  sublabel: 'days',
                  icon: Icons.local_fire_department_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _DayLabels(),
          SizedBox(height: 8.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6.h,
              crossAxisSpacing: 6.w,
            ),
            itemCount: days.length,
            itemBuilder: (_, i) => CalendarDayCell(
              day: days[i],
              onTap: () => context.push(AppRoutes.dayDetail),
            ),
          ),
          SizedBox(height: 12.h),
          const _Legend(),
          SizedBox(height: 16.h),
          CardContainer.gold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INSIGHT',
                  style: AppTextStyles.label(context).copyWith(color: AppColors.gold),
                ),
                SizedBox(height: 6.h),
                Text(kHadiths[1], style: AppTextStyles.bodyLarge(context)),
              ],
            ),
          ),
          SizedBox(height: 12.h),
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
                        'Weakest amal',
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Evening Azkar — missed 8 days this month',
                        style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp),
                      ),
                    ],
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

class _DayLabels extends StatelessWidget {
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
                style: AppTextStyles.label(context).copyWith(
                  color: AppColors.textMuted,
                ),
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
        Text('Full', style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp)),
        SizedBox(width: 12.w),
        _dot(AppColors.warning),
        SizedBox(width: 6.w),
        Text('Partial', style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp)),
        SizedBox(width: 12.w),
        _dot(AppColors.danger),
        SizedBox(width: 6.w),
        Text('Miss', style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp)),
      ],
    );
  }
}
