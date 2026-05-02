import 'package:flutter/material.dart';

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

  const CardContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.onTap,
    this.border,
    this.boxShadow,
  });

  factory CardContainer.gold({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.lg),
    EdgeInsetsGeometry? margin,
    double radius = AppRadius.lg,
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
        borderRadius: BorderRadius.circular(radius),
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
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: container,
      ),
    );
  }
}
