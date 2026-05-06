import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/amal_fields.dart' as amal_const;
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';

class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final score = kTodayAmalEntries.fold<int>(
      0,
      (s, e) => s + e.earnedPoints,
    );
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => context.canPop() ? context.pop() : context.go('/history'),
        ),
        title: Text('14 Shawwal 1447', style: AppTextStyles.headlineMedium(context)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(99.r),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  'READ-ONLY',
                  style: AppTextStyles.label(context).copyWith(
                    fontSize: 10.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 4.h, 0, 24.h),
        children: [
          Text(
            'Tuesday',
            style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.gold),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Score',
                  value: '$score',
                  sublabel: 'of 100',
                  icon: Icons.workspace_premium_outlined,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: StatCard(
                  label: 'Streak that day',
                  value: '14',
                  sublabel: 'days',
                  icon: Icons.local_fire_department_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text("Amal", style: AppTextStyles.headlineMedium(context)),
          SizedBox(height: 8.h),
          ...kTodayAmalEntries.map((entry) {
            final field = amal_const.kAmalFields.firstWhere(
              (f) => f.id == entry.fieldId,
              orElse: () => amal_const.kAmalFields.first,
            );
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: AmalRow(
                field: field,
                done: entry.done,
                numericValue: entry.value,
                readOnly: true,
              ),
            );
          }),
          SizedBox(height: 14.h),
          CardContainer(
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: AppColors.textMuted,
                  size: 16.r,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Past days are locked. Stay consistent today.',
                    style: AppTextStyles.bodyMedium(context),
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
