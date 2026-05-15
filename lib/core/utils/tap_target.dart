import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Minimum touch target slop used across amal controls (~48dp).
EdgeInsets amalControlHitSlop() =>
    EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h);

/// Expands the tappable region beyond [child] bounds without changing layout.
class HitSlopWrapper extends StatelessWidget {
  const HitSlopWrapper({
    super.key,
    required this.child,
    required this.onTap,
    this.hitSlop,
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets? hitSlop;

  @override
  Widget build(BuildContext context) {
    final slop = hitSlop ?? amalControlHitSlop();
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          left: -slop.left,
          right: -slop.right,
          top: -slop.top,
          bottom: -slop.bottom,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onTap,
          ),
        ),
        child,
      ],
    );
  }
}

/// Wraps [child] with expanded hit area and optional [onTap].
class ExpandedTapTarget extends StatelessWidget {
  const ExpandedTapTarget({
    super.key,
    required this.child,
    this.onTap,
    this.hitSlop,
    this.minWidth,
    this.minHeight,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? hitSlop;
  final double? minWidth;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (minWidth != null || minHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth ?? 0,
          minHeight: minHeight ?? 0,
        ),
        child: Center(child: child),
      );
    }

    if (onTap == null) {
      return content;
    }

    return HitSlopWrapper(
      hitSlop: hitSlop,
      onTap: onTap!,
      child: content,
    );
  }
}
