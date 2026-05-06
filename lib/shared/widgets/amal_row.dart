import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/amal_fields.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import 'card_container.dart';

IconData amalFieldIcon(String id) {
  switch (id) {
    case 'fard':
      return Icons.circle_outlined;
    case 'takbir':
      return Icons.star_outline;
    case 'morning_azkar':
      return Icons.wb_sunny_outlined;
    case 'evening_azkar':
      return Icons.nightlight_outlined;
    case 'quran':
      return Icons.menu_book_outlined;
    case 'mulk':
      return Icons.bookmark_outline;
    case 'miswak':
      return Icons.cleaning_services_outlined;
    case 'sunnah':
      return Icons.brightness_low_outlined;
    case 'post_azkar':
      return Icons.access_time_outlined;
    default:
      return Icons.check_circle_outline;
  }
}

class AmalRow extends StatelessWidget {
  final AmalField field;
  final bool done;
  final int? numericValue;
  final ValueChanged<bool>? onChanged;
  final bool readOnly;

  const AmalRow({
    super.key,
    required this.field,
    required this.done,
    this.numericValue,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      color: done ? AppColors.goldCard : AppColors.cardDark,
      borderColor: done ? AppColors.goldBorder : AppColors.cardBorder,
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? AppColors.gold : AppColors.cardBorder,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              amalFieldIcon(field.id),
              color: done ? AppColors.emeraldDeep : AppColors.textSecondary,
              size: 18.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      field.sublabel,
                      style:
                          AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      width: 3.r,
                      height: 3.r,
                      decoration: const BoxDecoration(
                        color: AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '+${field.points} pts',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 11.sp,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          if (readOnly)
            Icon(
              done
                  ? Icons.check_circle
                  : (numericValue != null && numericValue! > 0
                        ? Icons.adjust
                        : Icons.cancel_outlined),
              color: done
                  ? AppColors.success
                  : (numericValue != null && numericValue! > 0
                        ? AppColors.warning
                        : AppColors.danger),
              size: 22.r,
            )
          else
            Switch.adaptive(
              value: done,
              onChanged: onChanged,
              activeThumbColor: AppColors.emeraldDeep,
              activeTrackColor: AppColors.gold,
            ),
        ],
      ),
    );
  }
}
