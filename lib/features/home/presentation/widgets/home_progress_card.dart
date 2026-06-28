import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';

class HomeProgressCard extends StatelessWidget {
  const HomeProgressCard({
    super.key,
    required this.done,
    required this.total,
    required this.score,
    required this.maxScore,
  });

  final int done;
  final int total;
  final int score;
  final int maxScore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CardContainer(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.todaysProgress,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              Text(
                '$done/$total',
                style: AppTextStyles.goldNumeric(
                  context,
                ).copyWith(fontSize: 14.sp),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ScoreBar(value: total == 0 ? 0 : done / total, height: 4),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.gold,
                size: 14.r,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  l10n.scoreOutOfPoints(score, maxScore),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
