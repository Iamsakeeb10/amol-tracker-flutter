import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/husna_name_model.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final meaning = name.localizedMeaningFromLocale(Localizations.localeOf(context));

    return Card(
      color: isLearned ? AppColors.goldCard : AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isLearned ? AppColors.goldBorder : AppColors.cardBorder,
          width: 1.r,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(10.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldMid,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      l10n.husnaNumber(name.number),
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isLearned)
                    Icon(Icons.check_circle, color: AppColors.success, size: 16.r),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                name.arabic,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                name.transliteration,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                meaning,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10.sp,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
