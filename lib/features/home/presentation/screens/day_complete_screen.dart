import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/hadith_asset_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/constants/default_amal_fields.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/streak_badge.dart';

class DayCompleteScreen extends ConsumerStatefulWidget {
  const DayCompleteScreen({super.key, required this.log});

  final AmalLogModel log;

  @override
  ConsumerState<DayCompleteScreen> createState() => _DayCompleteScreenState();
}

class _DayCompleteScreenState extends ConsumerState<DayCompleteScreen> {
  String? _hadith;
  String? _hadithError;

  @override
  void initState() {
    super.initState();
    _pickHadith();
  }

  Future<void> _pickHadith() async {
    try {
      final hadiths = await HadithAssetService.loadHadithTexts();

      if (!mounted) return;

      if (hadiths.isEmpty) {
        setState(() {
          _hadithError = 'কোনো হাদিস পাওয়া যায়নি';
        });
        return;
      }

      final i = Random().nextInt(hadiths.length);

      setState(() {
        _hadith = hadiths[i];
        _hadithError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hadithError = 'হাদিস লোড করতে সমস্যা হয়েছে';
      });
    }
  }

  void _goHome(BuildContext context) {
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final log = widget.log;
    final locale = Localizations.localeOf(context).languageCode;
    final fieldsAsync = ref.watch(amalFieldsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goHome(context);
      },
      child: AppScaffold(
        handleExitBack: false,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.close, size: 22.r),
            onPressed: () => _goHome(context),
          ),
        ),
        body: fieldsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
          error: (_, __) => Center(
            child: Text(
              l10n.dayDetailLoadFailed,
              style: AppTextStyles.bodyMedium(context),
            ),
          ),
          data: (fields) {
            final maxScore = getMaxScore(fields).clamp(1, kDefaultMaxDailyScore);
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Center(
                          child: _ScoreRing(score: log.score, maxScore: maxScore),
                        ),
                        SizedBox(height: 18.h),
                        Text(
                          'Alhamdulillah',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displayMedium(context),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          l10n.dayCompleteSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(context),
                        ),
                        SizedBox(height: 12.h),
                        Center(
                          child: Pill(
                            text: l10n.pointsEarned(log.score),
                            icon: Icons.bolt,
                          ),
                        ),
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
                                    l10n.hadithOfDay,
                                    style: AppTextStyles.label(
                                      context,
                                    ).copyWith(color: AppColors.gold),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              if (_hadith != null)
                                Text(
                                  _hadith!,
                                  style: AppTextStyles.bodyLarge(context),
                                )
                              else if (_hadithError != null)
                                Text(
                                  _hadithError!,
                                  style: AppTextStyles.bodyMedium(
                                    context,
                                  ).copyWith(color: AppColors.textMuted),
                                )
                              else
                                const _HadithLoadingShimmer(),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          l10n.todaysSummary,
                          style: AppTextStyles.headlineMedium(context),
                        ),
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  sliver: SliverList.builder(
                    itemCount: fields.length,
                    itemBuilder: (context, index) {
                      final field = fields[index];
                      final numericValue = field.type == AmalType.numeric
                          ? getNumericValue(
                              log.toggles[field.id],
                              field.maxValue,
                            )
                          : null;
                      final done = field.type == AmalType.numeric
                          ? numericValue! > 0
                          : (log.toggles[field.id] as bool? ?? false);
                      final earned = field.type == AmalType.numeric
                          ? ((numericValue! / field.maxValue) * field.points)
                                .round()
                          : (done ? field.points : 0);
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: _SummaryRow(
                          field: field,
                          locale: locale,
                          done: done,
                          numericValue: numericValue,
                          earnedPoints: earned,
                        ),
                      );
                    },
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(8.w, 18.h, 8.w, 28.h),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
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
                          l10n.backToHome,
                          style: AppTextStyles.button(context).copyWith(
                            color: AppColors.emeraldDeep,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HadithLoadingShimmer extends StatelessWidget {
  const _HadithLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          Container(
            width: double.infinity,
            height: 11.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.r),
            ),
          ),
          SizedBox(height: 7.h),
          Container(
            width: double.infinity,
            height: 11.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.r),
            ),
          ),
          SizedBox(height: 7.h),
          Container(
            width: 160.w,
            height: 11.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.r),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;
  final int maxScore;

  const _ScoreRing({required this.score, required this.maxScore});

  @override
  Widget build(BuildContext context) {
    final dim = 180.r;
    final target = (score / maxScore).clamp(0.0, 1.0);
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
                    style: AppTextStyles.displayLarge(
                      context,
                    ).copyWith(color: AppColors.goldLight, fontSize: 56.sp),
                  ),
                  Text(
                    '/$maxScore',
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(fontSize: 11.sp),
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
  final String locale;
  final bool done;
  final int? numericValue;
  final int earnedPoints;

  const _SummaryRow({
    required this.field,
    required this.locale,
    required this.done,
    this.numericValue,
    required this.earnedPoints,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = done ? AppColors.success : AppColors.danger;
    final iconData = done ? Icons.check_circle : Icons.cancel_outlined;
    final isNumeric = field.type == AmalType.numeric;
    final value = numericValue ?? 0;

    return CardContainer(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: [
          if (isNumeric)
            Text(
              '${_toBengaliNumeral(value)}/${_toBengaliNumeral(field.maxValue)}',
              style: AppTextStyles.pill(context).copyWith(
                color: value > 0 ? AppColors.gold : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Icon(iconData, color: iconColor, size: 20.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              field.getLabel(locale),
              style: AppTextStyles.bodyLarge(context).copyWith(fontSize: 14.sp),
            ),
          ),
          Text(
            AppLocalizations.of(context)!.pointsValue(earnedPoints),
            style: AppTextStyles.pill(context).copyWith(
              color: earnedPoints > 0 ? AppColors.gold : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

String _toBengaliNumeral(int number) {
  const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return number
      .toString()
      .split('')
      .map((digit) => bnDigits[int.parse(digit)])
      .join();
}
