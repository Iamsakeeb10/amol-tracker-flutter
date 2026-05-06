import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import 'card_container.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sublabel;
  final IconData? icon;
  final Color? accentColor;

  /// Larger type; surface matches locked badge cards (e.g. [MockBadge] `30-Day Streak`
  /// in `kBadges`: [AppColors.cardDark]) without border.
  final bool prominent;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.sublabel,
    this.icon,
    this.accentColor,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 90.h || constraints.maxWidth < 120.w;
        final accent = accentColor ?? AppColors.gold;
        final pad = prominent
            ? (isCompact ? AppSpacing.md : AppSpacing.lg).r
            : (isCompact ? AppSpacing.sm : AppSpacing.md).r;

        final labelSize = prominent
            ? (isCompact ? 11.5 : 13.0).sp
            : (isCompact ? 10.0 : 11.0).sp;
        final valueSize = prominent
            ? (isCompact ? 22.0 : 28.0).sp
            : (isCompact ? 18.0 : 22.0).sp;
        final subSize = prominent
            ? (isCompact ? 10.5 : 11.5).sp
            : (isCompact ? 9.0 : 10.0).sp;
        final iconSize = prominent
            ? (isCompact ? 15.0 : 18.0).r
            : (isCompact ? 12.0 : 14.0).r;

        Widget valueWidget() {
          final baseStyle = AppTextStyles.goldNumeric(context).copyWith(
            fontSize: valueSize,
            fontWeight: prominent ? FontWeight.w800 : FontWeight.w600,
            height: 1.05,
            color: accentColor ?? AppColors.goldLight,
          );
          return Text(value, style: baseStyle);
        }

        final column = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: iconSize, color: accent),
                  SizedBox(width: prominent ? 6.w : 4.w),
                ],
                Expanded(
                  child: Text(
                    prominent ? label.toUpperCase() : label,
                    style: prominent
                        ? AppTextStyles.label(context).copyWith(
                            fontSize: labelSize,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          )
                        : AppTextStyles.bodySmall(context).copyWith(
                            fontSize: labelSize,
                          ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: (prominent ? (isCompact ? 6 : 8) : (isCompact ? 4 : 6)).h),
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: valueWidget(),
              ),
            ),
            if (sublabel != null) ...[
              SizedBox(height: prominent ? 4.h : 2.h),
              Text(
                sublabel!,
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontSize: subSize,
                  fontWeight: prominent ? FontWeight.w600 : FontWeight.w400,
                  color: prominent ? AppColors.goldPale : AppColors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ],
        );

        if (prominent) {
          return CardContainer(
            padding: EdgeInsets.all(pad),
            color: AppColors.cardDark,
            border: Border.all(color: Colors.transparent, width: 0),
            child: column,
          );
        }

        return CardContainer(
          padding: EdgeInsets.all(pad),
          borderColor: AppColors.cardBorder,
          child: column,
        );
      },
    );
  }
}
