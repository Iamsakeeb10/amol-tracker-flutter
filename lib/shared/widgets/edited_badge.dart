import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

/// Small chip shown when an amal log has been edited at least once.
class EditedBadge extends StatelessWidget {
  const EditedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.goldCard,
        borderRadius: BorderRadius.circular(99.r),
        border: Border.all(color: AppColors.goldBorder),
      ),
      child: Text(
        'সম্পাদিত',
        style: AppTextStyles.label(context).copyWith(
          fontSize: 10.sp,
          color: AppColors.gold,
        ),
      ),
    );
  }
}
