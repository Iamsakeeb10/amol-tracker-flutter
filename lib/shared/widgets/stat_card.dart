import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import 'card_container.dart';

/// Computes a grid aspect ratio that keeps [StatCard] cells tall enough on narrow screens.
double profileStatGridAspectRatio(
  BuildContext context, {
  int crossAxisCount = 3,
  double extraHorizontalPadding = 0,
  double crossAxisSpacing = 8,
  double minCellHeight = 104,
}) {
  final width = MediaQuery.sizeOf(context).width;
  const scaffoldHorizontalPadding = 40.0;
  final spacing = crossAxisSpacing.w * (crossAxisCount - 1);
  final cellWidth = (width -
          scaffoldHorizontalPadding.w -
          extraHorizontalPadding.w -
          spacing) /
      crossAxisCount;
  final cellHeight = minCellHeight.h;
  if (cellHeight <= 0) return 1.2;
  return cellWidth / cellHeight;
}

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
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;
        final isCompact = maxHeight < 90.h || maxWidth < 120.w;
        final isTight = maxHeight.isFinite && maxHeight < 98.h;
        final accent = accentColor ?? AppColors.gold;
        final pad = prominent
            ? ((isTight || isCompact) ? AppSpacing.sm : AppSpacing.lg).r
            : (isCompact ? AppSpacing.sm : AppSpacing.md).r;

        final labelSize = prominent
            ? (isTight ? 10.0 : isCompact ? 11.5 : 13.0).sp
            : (isCompact ? 10.0 : 11.0).sp;
        final valueSize = prominent
            ? (isTight ? 18.0 : isCompact ? 22.0 : 28.0).sp
            : (isCompact ? 18.0 : 22.0).sp;
        final subSize = prominent
            ? (isTight ? 9.0 : isCompact ? 10.5 : 11.5).sp
            : (isCompact ? 9.0 : 10.0).sp;
        final iconSize = prominent
            ? (isTight ? 13.0 : isCompact ? 15.0 : 18.0).r
            : (isCompact ? 12.0 : 14.0).r;
        final labelGap = (prominent
                ? (isTight ? 3 : isCompact ? 6 : 8)
                : (isCompact ? 4 : 6))
            .h;
        final subGap = (prominent ? (isTight ? 2 : 4) : 2).h;

        final innerHeight = maxHeight.isFinite
            ? (maxHeight - pad * 2).clamp(0.0, double.infinity)
            : null;
        final innerWidth = maxWidth.isFinite
            ? (maxWidth - pad * 2).clamp(0.0, double.infinity)
            : null;
        final contentWidth = innerWidth ?? maxWidth;

        Widget buildColumn() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (contentWidth.isFinite)
                SizedBox(
                  width: contentWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: iconSize, color: accent),
                        SizedBox(width: prominent ? 6.w : 4.w),
                      ],
                      Flexible(
                        child: Text(
                          prominent ? label.toUpperCase() : label,
                          style: prominent
                              ? AppTextStyles.label(context).copyWith(
                                  fontSize: labelSize,
                                  letterSpacing: isTight ? 0.6 : 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                  height: 1.1,
                                )
                              : AppTextStyles.bodySmall(context).copyWith(
                                  fontSize: labelSize,
                                  height: 1.1,
                                ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: iconSize, color: accent),
                      SizedBox(width: prominent ? 6.w : 4.w),
                    ],
                    Text(
                      prominent ? label.toUpperCase() : label,
                      style: prominent
                          ? AppTextStyles.label(context).copyWith(
                              fontSize: labelSize,
                              letterSpacing: isTight ? 0.6 : 1.2,
                              fontWeight: FontWeight.w700,
                              color: accent,
                              height: 1.1,
                            )
                          : AppTextStyles.bodySmall(context).copyWith(
                              fontSize: labelSize,
                              height: 1.1,
                            ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              SizedBox(height: labelGap),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.goldNumeric(context).copyWith(
                    fontSize: valueSize,
                    fontWeight: prominent ? FontWeight.w800 : FontWeight.w600,
                    height: 1.05,
                    color: accentColor ?? AppColors.goldLight,
                  ),
                ),
              ),
              if (sublabel != null) ...[
                SizedBox(height: subGap),
                Text(
                  sublabel!,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontSize: subSize,
                    fontWeight: prominent ? FontWeight.w600 : FontWeight.w400,
                    color: prominent ? AppColors.goldPale : AppColors.textMuted,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ],
          );
        }

        final column = buildColumn();

        final Widget body;
        if (innerHeight != null && innerHeight > 0 && innerWidth != null) {
          body = SizedBox(
            height: innerHeight,
            width: innerWidth,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: innerWidth),
                  child: column,
                ),
              ),
            ),
          );
        } else {
          body = Center(child: column);
        }

        if (prominent) {
          return CardContainer(
            padding: EdgeInsets.all(pad),
            color: AppColors.cardDark,
            border: Border.all(color: Colors.transparent, width: 0),
            child: body,
          );
        }

        return CardContainer(
          padding: EdgeInsets.all(pad),
          borderColor: AppColors.cardBorder,
          child: body,
        );
      },
    );
  }
}
