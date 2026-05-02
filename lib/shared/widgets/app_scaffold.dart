import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showGeoBackground;
  final EdgeInsetsGeometry? padding;
  final bool safeAreaBottom;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showGeoBackground = true,
    this.padding,
    this.safeAreaBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.emeraldDeep,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.6),
                  radius: 1.4,
                  colors: [
                    AppColors.emeraldLight,
                    AppColors.emeraldMid,
                    AppColors.emeraldDeep,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          if (showGeoBackground) const Positioned.fill(child: _GeoOverlay()),
          SafeArea(
            bottom: safeAreaBottom,
            child: Padding(
              padding: padding ??
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

class _GeoOverlay extends StatelessWidget {
  const _GeoOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _GeoPainter(), size: Size.infinite),
    );
  }
}

class _GeoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.r;

    canvas.drawCircle(Offset(size.width * 0.85, 80.h), 60.r, paint);
    canvas.drawCircle(Offset(size.width * 0.85, 80.h), 40.r, paint);
    canvas.drawCircle(Offset(-30.w, size.height * 0.5), 90.r, paint);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height - 60.h),
      120.r,
      paint..color = AppColors.gold.withValues(alpha: 0.04),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
