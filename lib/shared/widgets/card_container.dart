import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';

class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  CardContainer({
    super.key,
    required this.child,
    EdgeInsetsGeometry? padding,
    this.margin,
    this.color,
    this.borderColor,
    double? radius,
    this.onTap,
    this.border,
    this.boxShadow,
  })  : padding = padding ?? EdgeInsets.all(AppSpacing.lg.r),
        radius = radius ?? AppRadius.lg;

  factory CardContainer.gold({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? radius,
    VoidCallback? onTap,
  }) {
    return CardContainer(
      key: key,
      padding: padding,
      margin: margin,
      color: AppColors.goldCard,
      borderColor: AppColors.goldBorder,
      radius: radius,
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final container = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.cardDark,
        borderRadius: BorderRadius.circular(radius.r),
        border:
            border ?? Border.all(color: borderColor ?? AppColors.cardBorder),
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (onTap == null) return container;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius.r),
        onTap: onTap,
        child: container,
      ),
    );
  }
}
