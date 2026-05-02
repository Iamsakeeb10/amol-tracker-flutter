import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../mock/mock_data.dart';
import 'card_container.dart';
import 'score_bar.dart';

class BadgeTile extends StatelessWidget {
  final MockBadge badge;

  const BadgeTile({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.unlocked;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 130.h || constraints.maxWidth < 158.w;
        final pad = (compact ? AppSpacing.sm : AppSpacing.md).r;
        final iconSize = (compact ? 34 : 40).r;
        final iconInner = (compact ? 17 : 20).r;

        return CardContainer(
          padding: EdgeInsets.all(pad),
          color: unlocked ? AppColors.goldCard : AppColors.cardDark,
          borderColor: unlocked ? AppColors.goldBorder : AppColors.cardBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: unlocked
                      ? AppColors.gold
                      : AppColors.cardBorder.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  badge.icon,
                  color: unlocked ? AppColors.emeraldDeep : AppColors.textMuted,
                  size: iconInner,
                ),
              ),
              SizedBox(height: (compact ? 6 : 10).h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.title,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontSize: (compact ? 12 : 13).sp,
                        fontWeight: FontWeight.w500,
                        color: unlocked
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Expanded(
                      child: Text(
                        badge.description,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          fontSize: (compact ? 10 : 11).sp,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!unlocked) ...[
                      SizedBox(height: (compact ? 6 : 8).h),
                      ScoreBar(value: badge.progress, height: 4),
                      SizedBox(height: (compact ? 3 : 4).h),
                      Text(
                        '${(badge.progress * 100).toInt()}%',
                        style: AppTextStyles.bodySmall(context).copyWith(
                          fontSize: 10.sp,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
