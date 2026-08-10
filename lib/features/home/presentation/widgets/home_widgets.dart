import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/card_container.dart';

export 'home_progress_card.dart';
export 'home_quick_nav_section.dart';
export 'home_top_performers.dart';
export 'home_submitted_amal_sliver.dart';
export 'knowledge_battle_banner.dart';
abstract final class HomeUiColors {
  static final offlineBannerBg =
      AppColors.warningLight.withValues(alpha: 0.35);
  static final offlineBannerBorder =
      AppColors.warning.withValues(alpha: 0.5);
  static final warningButtonBorder =
      AppColors.warning.withValues(alpha: 0.65);
  static final statusCardBg = AppColors.warningLight.withValues(alpha: 0.25);
  static final statusCardBorder = AppColors.warning.withValues(alpha: 0.35);
}

class HomeSubmittedAmalIconButton extends StatelessWidget {
  const HomeSubmittedAmalIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.iconColor = AppColors.gold,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color iconColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: 40.r,
            height: 40.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.goldCard,
              border: Border.all(color: AppColors.goldBorder),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: iconColor, size: 20.r),
          ),
        ),
      ),
    );
  }
}

class HomeDetailChip extends StatelessWidget {
  const HomeDetailChip({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.goldCard,
        borderRadius: BorderRadius.circular(99.r),
        border: Border.all(color: AppColors.goldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 14.r),
          SizedBox(width: 6.w),
          Text(
            text,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeAmalFieldsStatusCard extends StatelessWidget {
  const HomeAmalFieldsStatusCard({
    super.key,
    required this.message,
    this.showRetry = false,
    this.onRetry,
  });

  final String message;
  final bool showRetry;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      color: HomeUiColors.statusCardBg,
      borderColor: HomeUiColors.statusCardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppTextStyles.bodyMedium(context)),
          if (showRetry && onRetry != null) ...[
            SizedBox(height: 10.h),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
