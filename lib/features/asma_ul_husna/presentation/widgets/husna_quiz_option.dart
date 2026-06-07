import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../models/husna_name_model.dart';

enum HusnaQuizOptionState { idle, correct, wrong }

class HusnaQuizOption extends StatelessWidget {
  const HusnaQuizOption({
    super.key,
    required this.name,
    required this.state,
    required this.enabled,
    required this.onTap,
  });

  final HusnaName name;
  final HusnaQuizOptionState state;
  final bool enabled;
  final VoidCallback onTap;

  Color _backgroundColor() {
    switch (state) {
      case HusnaQuizOptionState.correct:
        return AppColors.successLight;
      case HusnaQuizOptionState.wrong:
        return AppColors.dangerLight;
      case HusnaQuizOptionState.idle:
        return AppColors.cardDark;
    }
  }

  Color _borderColor() {
    switch (state) {
      case HusnaQuizOptionState.correct:
        return AppColors.success;
      case HusnaQuizOptionState.wrong:
        return AppColors.danger;
      case HusnaQuizOptionState.idle:
        return AppColors.cardBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _backgroundColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: _borderColor(), width: 1.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name.transliteration,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              if (state == HusnaQuizOptionState.correct)
                Icon(Icons.check_circle, color: AppColors.success, size: 20.r),
              if (state == HusnaQuizOptionState.wrong)
                Icon(Icons.cancel, color: AppColors.danger, size: 20.r),
            ],
          ),
        ),
      ),
    );
  }
}
