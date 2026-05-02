import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';
import '../../../../shared/widgets/streak_freeze_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Map<String, bool> _toggles;

  @override
  void initState() {
    super.initState();
    _toggles = {
      'fard': true,
      'takbir': true,
      'morning_azkar': true,
      'evening_azkar': false,
      'quran': true,
      'mulk': true,
      'miswak': true,
      'sunnah': true,
      'post_azkar': false,
    };
  }

  int get _doneCount => _toggles.values.where((v) => v).length;
  int get _totalScore {
    int s = 0;
    for (final f in kAmalFields) {
      if (_toggles[f.id] == true) s += f.points;
    }
    return s;
  }

  void _markAllDone() {
    setState(() {
      for (final k in _toggles.keys.toList()) {
        _toggles[k] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      padding: EdgeInsets.zero,
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 96.h),
        children: [
          _Header(),
          SizedBox(height: 18.h),
          _StreakBanner(streak: kCurrentUser.currentStreak),
          SizedBox(height: 14.h),
          _ProgressCard(
            done: _doneCount,
            total: _toggles.length,
            score: _totalScore,
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: Text("Today's Amal", style: AppTextStyles.headlineMedium(context)),
              ),
              TextButton(
                onPressed: _markAllDone,
                child: Text(
                  'Mark all',
                  style: AppTextStyles.button(context).copyWith(color: AppColors.gold),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ...kAmalFields.map((f) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: AmalRow(
                  field: f,
                  done: _toggles[f.id] ?? false,
                  onChanged: (v) => setState(() => _toggles[f.id] = v),
                ),
              )),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.dayComplete),
                  icon: Icon(Icons.check_circle_outline, size: 16.r),
                  label: const Text('Day complete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.goldBorder),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: () => StreakFreezeModal.show(context),
                icon: Icon(Icons.ac_unit, color: AppColors.gold, size: 22.r),
                tooltip: 'Streak freeze',
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: EdgeInsets.all(14.r),
                ),
              ),
              SizedBox(width: 4.w),
              IconButton(
                onPressed: () => context.push(AppRoutes.emptyState),
                icon: Icon(
                  Icons.hourglass_empty,
                  color: AppColors.textMuted,
                  size: 22.r,
                ),
                tooltip: 'Empty state preview',
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: EdgeInsets.all(14.r),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '24 Shawwal 1447',
                style: AppTextStyles.label(context).copyWith(color: AppColors.gold),
              ),
              SizedBox(height: 2.h),
              Text('Sunday', style: AppTextStyles.displayMedium(context)),
            ],
          ),
        ),
        AvatarChip(
          initial: 'Y',
          color: AppColors.gold,
          ring: true,
          size: 38,
          fontSize: 16,
        ),
      ],
    );
  }
}

class _StreakBanner extends StatelessWidget {
  final int streak;
  const _StreakBanner({required this.streak});

  @override
  Widget build(BuildContext context) {
    return CardContainer.gold(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.local_fire_department,
              color: AppColors.warning,
              size: 22.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$streak-day streak',
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(99.r),
                      ),
                      child: Text(
                        'on fire',
                        style: AppTextStyles.pill(context).copyWith(
                          color: AppColors.warning,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'Best: 41 days · keep it going',
                  style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int done;
  final int total;
  final int score;

  const _ProgressCard({
    required this.done,
    required this.total,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's progress",
                  style: AppTextStyles.bodyMedium(context),
                ),
              ),
              Text(
                '$done/$total',
                style: AppTextStyles.goldNumeric(context).copyWith(fontSize: 18.sp),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ScoreBar(value: total == 0 ? 0 : done / total),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.gold,
                size: 14.r,
              ),
              SizedBox(width: 6.w),
              Text(
                '$score / $kMaxDailyScore points',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
