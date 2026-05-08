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
  final ValueChanged<int>? onNumericChanged;
  final VoidCallback? onTapDetails;
  final int? maxAllowed;
  final bool readOnly;

  const AmalRow({
    super.key,
    required this.field,
    required this.done,
    this.numericValue,
    this.onChanged,
    this.onNumericChanged,
    this.onTapDetails,
    this.maxAllowed,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isNumeric = field.type == AmalType.numeric;
    final currentNumeric = (numericValue ?? 0).clamp(0, field.maxValue);
    final effectiveMax = isNumeric
        ? field.maxValue.clamp(0, maxAllowed ?? field.maxValue)
        : field.maxValue;
    final earnedPoints = isNumeric
        ? ((currentNumeric / field.maxValue) * field.points).round()
        : (done ? field.points : 0);

    return CardContainer(
      onTap: onTapDetails,
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
                  field.labelBn,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        field.sublabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall(context)
                            .copyWith(fontSize: 11.sp),
                      ),
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
                      '+$earnedPoints/${field.points} pts',
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
          if (isNumeric)
            _NumericControl(
              currentValue: currentNumeric,
              maxValue: effectiveMax,
              fieldMaxValue: field.maxValue,
              readOnly: readOnly,
              onChanged: onNumericChanged,
            )
          else if (readOnly)
            Icon(
              done ? Icons.check_circle : Icons.cancel_outlined,
              color: done ? AppColors.success : AppColors.danger,
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

class _NumericControl extends StatelessWidget {
  const _NumericControl({
    required this.currentValue,
    required this.maxValue,
    required this.fieldMaxValue,
    required this.readOnly,
    required this.onChanged,
  });

  final int currentValue;
  final int maxValue;
  final int fieldMaxValue;
  final bool readOnly;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (readOnly) {
      return Text(
        '${_toBengaliNumeral(currentValue)}/${_toBengaliNumeral(fieldMaxValue)}',
        style: AppTextStyles.pill(context).copyWith(
          color: currentValue > 0 ? AppColors.gold : AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final canDecrement = currentValue > 0;
    final canIncrement = currentValue < maxValue;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove,
          enabled: canDecrement,
          onTap: () => onChanged?.call((currentValue - 1).clamp(0, maxValue)),
        ),
        SizedBox(width: 8.w),
        Container(
          width: 34.w,
          alignment: Alignment.center,
          child: Text(
            _toBengaliNumeral(currentValue),
            style: AppTextStyles.bodyLarge(context).copyWith(
              color: currentValue > 0 ? AppColors.gold : AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        _StepperButton(
          icon: Icons.add,
          enabled: canIncrement,
          onTap: () => onChanged?.call((currentValue + 1).clamp(0, maxValue)),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: 26.r,
        height: 26.r,
        decoration: BoxDecoration(
          color: enabled ? AppColors.goldCard : AppColors.cardBorder,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: enabled ? AppColors.goldBorder : AppColors.cardBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 16.r,
          color: enabled ? AppColors.gold : AppColors.textMuted,
        ),
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
