import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../models/husna_name_model.dart';
import '../../../../shared/widgets/card_container.dart';

class HusnaNameCard extends StatelessWidget {
  const HusnaNameCard({
    super.key,
    required this.name,
    required this.isLearned,
    required this.onTap,
  });

  final HusnaName name;
  final bool isLearned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meaning = name.localizedMeaningFromLocale(Localizations.localeOf(context));

    return CardContainer(
      margin: EdgeInsets.only(bottom: 10.h),
      color: isLearned ? AppColors.goldCard : AppColors.cardDark,
      borderColor: isLearned ? AppColors.goldBorder : AppColors.cardBorder,
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NumberBadge(number: name.number, isLearned: isLearned),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.arabic,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  name.pronunciationBn,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  name.transliteration,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.gold,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  meaning,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isLearned)
            Padding(
              padding: EdgeInsets.only(left: 6.w, top: 2.h),
              child: Icon(Icons.check_circle, color: AppColors.success, size: 18.r),
            ),
        ],
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number, required this.isLearned});

  final int number;
  final bool isLearned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.r,
      height: 36.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLearned ? AppColors.gold.withValues(alpha: 0.15) : AppColors.emeraldMid,
        border: Border.all(
          color: isLearned ? AppColors.gold : AppColors.cardBorder,
          width: 1.5.r,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: AppTextStyles.bodySmall(context).copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: isLearned ? AppColors.gold : AppColors.textPrimary,
        ),
      ),
    );
  }
}
