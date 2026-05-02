import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/streak_badge.dart';

class DayCompleteScreen extends StatelessWidget {
  const DayCompleteScreen({super.key});

  int get _totalEarned =>
      kTodayAmalEntries.fold<int>(0, (s, e) => s + e.earnedPoints);

  @override
  Widget build(BuildContext context) {
    final earned = _totalEarned;
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, size: 22.r),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.home),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 28.h),
        children: [
          SizedBox(height: 8.h),
          Center(child: _ScoreRing(score: earned)),
          SizedBox(height: 18.h),
          Text(
            "Alhamdulillah",
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium(context),
          ),
          SizedBox(height: 4.h),
          Text(
            "You completed today's amal.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context),
          ),
          SizedBox(height: 12.h),
          Center(child: Pill(text: '+$earned pts earned', icon: Icons.bolt)),
          SizedBox(height: 22.h),
          CardContainer(
            color: AppColors.goldCard,
            borderColor: AppColors.goldBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: AppColors.goldLight,
                      size: 16.r,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'HADITH OF THE DAY',
                      style: AppTextStyles.label(context).copyWith(color: AppColors.gold),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(kHadiths[0], style: AppTextStyles.bodyLarge(context)),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text("Today's summary", style: AppTextStyles.headlineMedium(context)),
          SizedBox(height: 8.h),
          ...kTodayAmalEntries.map((entry) {
            final field = kAmalFields.firstWhere(
              (f) => f.id == entry.fieldId,
              orElse: () => kAmalFields.first,
            );
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _SummaryRow(field: field, entry: entry),
            );
          }),
          SizedBox(height: 18.h),
          SizedBox(
            height: 50.h,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.emeraldDeep,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'Back to home',
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

class _ScoreRing extends StatelessWidget {
  final int score;
  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    final dim = 180.r;
    return SizedBox(
      width: dim,
      height: dim,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: dim,
            height: dim,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 10.r,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              backgroundColor: AppColors.cardBorder,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: AppTextStyles.displayLarge(context).copyWith(
                  color: AppColors.goldLight,
                  fontSize: 56.sp,
                ),
              ),
              Text(
                'of 100',
                style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final AmalField field;
  final MockAmalEntry entry;

  const _SummaryRow({required this.field, required this.entry});

  @override
  Widget build(BuildContext context) {
    final partial =
        !entry.done && entry.value != null && entry.value! > 0;
    Color iconColor;
    IconData iconData;

    if (entry.done) {
      iconColor = AppColors.success;
      iconData = Icons.check_circle;
    } else if (partial) {
      iconColor = AppColors.warning;
      iconData = Icons.adjust;
    } else {
      iconColor = AppColors.danger;
      iconData = Icons.cancel_outlined;
    }

    return CardContainer(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 20.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              field.label,
              style: AppTextStyles.bodyLarge(context).copyWith(fontSize: 14.sp),
            ),
          ),
          Text(
            '${entry.earnedPoints} pts',
            style: AppTextStyles.pill(context).copyWith(
              color: entry.earnedPoints > 0
                  ? AppColors.gold
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
