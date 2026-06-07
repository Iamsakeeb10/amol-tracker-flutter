import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/lms_level_config.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';

class LmsXpProfileSection extends StatelessWidget {
  const LmsXpProfileSection({super.key, required this.lmsXp});

  final int lmsXp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final levelInfo = lmsLevelFromXp(lmsXp);
    final title = lmsLevelTitle(levelInfo.tier, l10n);

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: AppColors.goldLight, size: 20.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  l10n.lmsXpSectionTitle,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99.r),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Text(
                l10n.lmsXpLabel(lmsXp),
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (!levelInfo.isMaxLevel)
                Text(
                  l10n.lmsXpToNextLevel(levelInfo.xpToNextLevel),
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10.sp,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          ScoreBar(value: levelInfo.progressToNext, height: 6),
        ],
      ),
    );
  }
}

class LmsLevelCompactChip extends StatelessWidget {
  const LmsLevelCompactChip({super.key, required this.lmsXp});

  final int lmsXp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = lmsLevelTitle(lmsLevelFromXp(lmsXp).tier, l10n);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Text(
        title,
        style: AppTextStyles.bodySmall(context).copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w600,
          fontSize: 10.sp,
        ),
      ),
    );
  }
}
