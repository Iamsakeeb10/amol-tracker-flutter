import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/card_container.dart';

class DuaSubCategoryRow extends StatelessWidget {
  const DuaSubCategoryRow({
    super.key,
    required this.index,
    required this.title,
    required this.onTap,
    this.isNested = false,
  });

  final int index;
  final String title;
  final VoidCallback onTap;
  final bool isNested;

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      margin: EdgeInsets.only(bottom: 8.h, left: isNested ? 12.w : 0),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      onTap: onTap,
      child: Row(
        children: [
          _NumberBadge(index: index, isNested: isNested),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20.r),
        ],
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.index, required this.isNested});

  final int index;
  final bool isNested;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.r,
      height: 36.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isNested ? Colors.transparent : AppColors.gold.withValues(alpha: 0.25),
        border: isNested
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.r)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: AppTextStyles.label(context).copyWith(
          color: AppColors.goldLight,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class DuaListRow extends StatelessWidget {
  const DuaListRow({
    super.key,
    required this.index,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final int index;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.25),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: AppTextStyles.label(context).copyWith(
                color: AppColors.goldLight,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trailing != null) trailing!,
          Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20.r),
        ],
      ),
    );
  }
}
