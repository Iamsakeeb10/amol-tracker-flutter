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
  }) : padding = padding ?? EdgeInsets.all(AppSpacing.lg.r),
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
    final borderRadius = BorderRadius.circular(radius.r);
    final resolvedColor = color ?? AppColors.cardDark;
    final resolvedSide = _resolveBorderSide();

    Widget content = Padding(padding: padding, child: child);

    // Material renders fill + border + clip in one atomic paint pass via its
    // ShapeBorder, which prevents the background fill from antialiasing
    // outside the border at rounded corners (the issue with separate
    // ClipRRect + foreground-border layers).
    Widget card = Material(
      color: resolvedColor,
      shape: RoundedRectangleBorder(
        side: resolvedSide,
        borderRadius: borderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap != null ? InkWell(onTap: onTap, child: content) : content,
    );

    if (boxShadow != null && boxShadow!.isNotEmpty) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: boxShadow,
        ),
        child: card,
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }

  BorderSide _resolveBorderSide() {
    final b = border;
    if (b is Border) return b.top;
    return BorderSide(color: borderColor ?? AppColors.cardBorder, width: 1.r);
  }
}
