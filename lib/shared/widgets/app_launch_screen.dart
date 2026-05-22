import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../l10n/app_localizations.dart';

/// Branded full-screen placeholder shown while the app paints its first route.
class AppLaunchScreen extends StatelessWidget {
  const AppLaunchScreen({super.key});

  static const _iconAsset = 'assets/images/icon_fg.png';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n?.appTitle ?? 'Amol Tracker';

    return Material(
      color: AppColors.emeraldDeep,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _LaunchBackground(),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                _LaunchLogo(),
                SizedBox(height: 22.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayMedium(context),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 56.w,
                  height: 1.5.r,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0),
                        AppColors.gold.withValues(alpha: 0.7),
                        AppColors.gold.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LaunchLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120.r,
      height: 120.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.goldCard,
            AppColors.emeraldMid.withValues(alpha: 0.4),
          ],
        ),
        border: Border.all(color: AppColors.goldBorder, width: 1.5.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.18),
            blurRadius: 28.r,
            spreadRadius: 2.r,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(18.r),
        child: Image.asset(
          AppLaunchScreen._iconAsset,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _LaunchBackground extends StatelessWidget {
  const _LaunchBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.55),
              radius: 1.35,
              colors: [
                AppColors.emeraldLight,
                AppColors.emeraldMid,
                AppColors.emeraldDeep,
              ],
              stops: [0.0, 0.48, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -80.h,
          right: -60.w,
          child: _GlowOrb(
            size: 220.r,
            color: AppColors.gold.withValues(alpha: 0.08),
          ),
        ),
        Positioned(
          bottom: -100.h,
          left: -70.w,
          child: _GlowOrb(
            size: 260.r,
            color: AppColors.emeraldLight.withValues(alpha: 0.35),
          ),
        ),
        Positioned(
          top: 0.42.sh,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 280.w,
              height: 280.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  width: 1.r,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
