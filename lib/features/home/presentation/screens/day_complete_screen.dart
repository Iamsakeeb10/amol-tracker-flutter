import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/streak_badge.dart';

class DayCompleteScreen extends StatefulWidget {
  const DayCompleteScreen({super.key, required this.log});

  final AmalLogModel log;

  @override
  State<DayCompleteScreen> createState() => _DayCompleteScreenState();
}

class _DayCompleteScreenState extends State<DayCompleteScreen> {
  static const _hadithAsset = 'assets/hadiths/hadiths.json';

  String? _hadith;
  String? _hadithError;

  @override
  void initState() {
    super.initState();
    _pickHadith();
  }

  Future<void> _pickHadith() async {
    try {
      final raw = await rootBundle.loadString(_hadithAsset);
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.isEmpty) {
        setState(() => _hadithError = 'No hadiths available.');
        return;
      }
      final strings = decoded.map((e) => e.toString()).toList();
      final i = Random().nextInt(strings.length);
      setState(() => _hadith = strings[i]);
    } catch (e) {
      setState(() => _hadithError = 'Could not load hadith.');
    }
  }

  void _goHome(BuildContext context) {
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goHome(context);
      },
      child: AppScaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.close, size: 22.r),
            onPressed: () => _goHome(context),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 28.h),
          children: [
            SizedBox(height: 8.h),
            Center(child: _ScoreRing(score: log.score)),
            SizedBox(height: 18.h),
            Text(
              'Alhamdulillah',
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
            Center(child: Pill(text: '+${log.score} pts earned', icon: Icons.bolt)),
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
                  if (_hadith != null)
                    Text(_hadith!, style: AppTextStyles.bodyLarge(context))
                  else if (_hadithError != null)
                    Text(
                      _hadithError!,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textMuted,
                      ),
                    )
                  else
                    SizedBox(
                      height: 48.h,
                      child: Center(
                        child: SizedBox(
                          width: 22.r,
                          height: 22.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text("Today's summary", style: AppTextStyles.headlineMedium(context)),
            SizedBox(height: 8.h),
            ...kAmalFields.map((field) {
              final done = log.toggles[field.id] ?? false;
              final earned = done ? field.points : 0;
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _SummaryRow(field: field, done: done, earnedPoints: earned),
              );
            }),
            SizedBox(height: 18.h),
            SizedBox(
              height: 50.h,
              child: ElevatedButton(
                onPressed: () => _goHome(context),
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
    final target = (score / kMaxDailyScore).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
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
                  value: value,
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
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final AmalField field;
  final bool done;
  final int earnedPoints;

  const _SummaryRow({
    required this.field,
    required this.done,
    required this.earnedPoints,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = done ? AppColors.success : AppColors.danger;
    final iconData = done ? Icons.check_circle : Icons.cancel_outlined;

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
            '$earnedPoints pts',
            style: AppTextStyles.pill(context).copyWith(
              color: earnedPoints > 0 ? AppColors.gold : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
