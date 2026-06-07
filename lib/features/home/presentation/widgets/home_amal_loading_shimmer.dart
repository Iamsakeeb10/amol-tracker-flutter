import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/colors.dart';

class HomeAmalLoadingShimmer extends StatelessWidget {
  const HomeAmalLoadingShimmer({super.key, this.rowCount = 9});

  final int rowCount;

  static final Color _shimmerHighlight =
      AppColors.emeraldMid.withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Shimmer.fromColors(
        baseColor: AppColors.cardDark,
        highlightColor: _shimmerHighlight,
        child: Column(
          children: List.generate(
            rowCount,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Container(
                height: 56.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
