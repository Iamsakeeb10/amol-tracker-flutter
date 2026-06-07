import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/badge_model.dart';
import '../../../../providers/badge_celebration_provider.dart';
import '../../../../providers/device_tier_provider.dart';

class BadgeCelebrationHost extends ConsumerWidget {
  const BadgeCelebrationHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final celebration = ref.watch(badgeCelebrationProvider);
    final reduceMotion = ref.watch(reduceMotionProvider);
    BadgeDefinition? badge;
    final badgeId = celebration.currentBadgeId;
    if (badgeId != null) {
      for (final item in kBadgeDefinitions) {
        if (item.id == badgeId) {
          badge = item;
          break;
        }
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (badge != null)
          _BadgeCelebrationOverlay(
            badge: badge,
            reduceMotion: reduceMotion,
            onComplete: () {
              ref
                  .read(badgeCelebrationProvider.notifier)
                  .completeCurrentCelebration();
            },
          ),
      ],
    );
  }
}

class _BadgeCelebrationOverlay extends StatefulWidget {
  const _BadgeCelebrationOverlay({
    required this.badge,
    required this.reduceMotion,
    required this.onComplete,
  });

  final BadgeDefinition badge;
  final bool reduceMotion;
  final VoidCallback onComplete;

  @override
  State<_BadgeCelebrationOverlay> createState() =>
      _BadgeCelebrationOverlayState();
}

class _BadgeCelebrationOverlayState extends State<_BadgeCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Pre-computed animations to avoid per-frame curve calculations
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.reduceMotion ? 1 : 2200,
      ),
    );
    if (!widget.reduceMotion) {
      _controller.forward();
    }

    // Bake the curve into a tween so Curves.transform is called once per frame
    // at the Animation level, not inside build()
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.77, curve: Curves.easeOutCubic),
      ),
    );

    // sin-based glow: approximate with a repeating curved animation
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _badgeTitle(l10n, widget.badge);
    final desc = _badgeDescription(l10n, widget.badge);

    // Static widgets are built once, outside AnimatedBuilder
    final titleText = Text(
      'Badge Unlocked',
      style: AppTextStyles.headlineLarge(context).copyWith(
        color: AppColors.goldPale,
        letterSpacing: 0.8,
        shadows: const [],
        decoration: TextDecoration.none,
      ),
    );

    final badgeTitleText = Text(
      title,
      textAlign: TextAlign.center,
      style: AppTextStyles.displayMedium(context).copyWith(
        color: AppColors.textPrimary,
        height: 1.05,
        shadows: const [],
        decoration: TextDecoration.none,
      ),
    );

    final descText = Text(
      desc,
      textAlign: TextAlign.center,
      style: AppTextStyles.bodyLarge(context).copyWith(
        color: AppColors.textSecondary,
        shadows: const [],
        decoration: TextDecoration.none,
      ),
    );

    final tapHint = Text(
      'Tap to continue',
      style: AppTextStyles.bodySmall(context).copyWith(
        color: AppColors.goldPale,
        shadows: const [],
        decoration: TextDecoration.none,
      ),
    );

    if (widget.reduceMotion) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: ColoredBox(
          color: AppColors.emeraldDeep.withValues(alpha: 0.94),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  titleText,
                  SizedBox(height: 24.h),
                  Icon(widget.badge.icon, size: 72.r, color: AppColors.gold),
                  SizedBox(height: 16.h),
                  badgeTitleText,
                  SizedBox(height: 10.h),
                  descText,
                  SizedBox(height: 18.h),
                  tapHint,
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: ColoredBox(
        color: AppColors.emeraldDeep.withValues(alpha: 0.94),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = MediaQuery.sizeOf(context).height * 0.62;
                  return SizedBox(
                    height: height,
                    width: double.infinity,
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => CustomPaint(
                          painter: _BurstPainter(progress: _controller.value),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    titleText,
                    SizedBox(height: 24.h),
                    AnimatedBuilder(
                      animation: _scaleAnim,
                      builder: (context, child) {
                        final iconScale = 0.7 + (_scaleAnim.value * 0.45);
                        final t = _glowAnim.value;
                        final glow =
                            (math.sin(t * math.pi * 6) * 0.5 + 0.5) * 0.8;

                        return Transform.scale(
                          scale: iconScale,
                          child: Container(
                            width: 132.r,
                            height: 132.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.goldLight.withValues(alpha: 0.95),
                                  AppColors.gold.withValues(alpha: 0.75),
                                  AppColors.gold.withValues(alpha: 0.2),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.goldLight.withValues(
                                    alpha: 0.55 + glow * 0.3,
                                  ),
                                  blurRadius: 34.r,
                                  spreadRadius: 2.r,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                        );
                      },
                      // Icon is constant — passed as child so it isn't rebuilt
                      child: Icon(
                        widget.badge.icon,
                        size: 64.r,
                        color: AppColors.emeraldDeep,
                      ),
                    ),

                    SizedBox(height: 24.h),
                    badgeTitleText,
                    SizedBox(height: 8.h),
                    descText,
                    SizedBox(height: 20.h),
                    tapHint,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _badgeTitle(AppLocalizations l10n, BadgeDefinition badge) {
    switch (badge.id) {
      case 'threeDays':
        return l10n.badgeThreeDaysTitle;
      case 'sevenDays':
        return l10n.badgeSevenDaysTitle;
      case 'fourteenDays':
        return l10n.badgeFourteenDaysTitle;
      case 'thirtyDays':
        return l10n.badgeThirtyDaysTitle;
      case 'sixtyDays':
        return l10n.badgeSixtyDaysTitle;
      case 'hundredDays':
        return l10n.badgeHundredDaysTitle;
      case 'topOfCommunity':
        return l10n.badgeTopCommunityTitle;
      case 'perfectWeek':
        return l10n.badgePerfectWeekTitle;
      case 'courseGraduate':
        return l10n.badgeCourseGraduateTitle;
      default:
        return badge.title;
    }
  }

  String _badgeDescription(AppLocalizations l10n, BadgeDefinition badge) {
    switch (badge.id) {
      case 'threeDays':
        return l10n.badgeThreeDaysDesc;
      case 'sevenDays':
        return l10n.badgeSevenDaysDesc;
      case 'fourteenDays':
        return l10n.badgeFourteenDaysDesc;
      case 'thirtyDays':
        return l10n.badgeThirtyDaysDesc;
      case 'sixtyDays':
        return l10n.badgeSixtyDaysDesc;
      case 'hundredDays':
        return l10n.badgeHundredDaysDesc;
      case 'topOfCommunity':
        return l10n.badgeTopCommunityDesc;
      case 'perfectWeek':
        return l10n.badgePerfectWeekDesc;
      case 'courseGraduate':
        return l10n.badgeCourseGraduateDesc;
      default:
        return badge.description;
    }
  }
}

// Dot positions are pre-computed once, not regenerated every frame
final List<(double, double, bool)> _burstDots = () {
  final rng = math.Random(37);
  return List.generate(28, (i) {
    final angle = rng.nextDouble() * math.pi * 2;
    return (math.cos(angle), math.sin(angle), i % 3 == 0);
  });
}();

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.progress});

  final double progress;

  // Reusable Paint objects — avoids allocation inside paint()
  static final _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  static final _rayPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2;
  static final _dotPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    final maxRadius = size.shortestSide * 0.48;

    _ringPaint.color = AppColors.goldPale.withValues(
      alpha: (1 - progress) * 0.55,
    );
    canvas.drawCircle(center, maxRadius * (0.35 + progress * 0.65), _ringPaint);

    const rays = 18;
    final innerR = maxRadius * 0.16;
    final fadeAlpha = (1 - progress) * 0.7;

    for (var i = 0; i < rays; i++) {
      final angle = (math.pi * 2 * i) / rays;
      final length = maxRadius * (0.25 + 0.65 * progress);
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      final start = Offset(
        center.dx + cosA * innerR,
        center.dy + sinA * innerR,
      );
      final end = Offset(center.dx + cosA * length, center.dy + sinA * length);
      _rayPaint.color = (i.isEven ? AppColors.goldLight : AppColors.cream)
          .withValues(alpha: fadeAlpha);
      canvas.drawLine(start, end, _rayPaint);
    }

    final spread = maxRadius * (0.35 + progress * 0.85);
    final dotAlpha = (1 - progress).clamp(0.0, 1.0);
    final dotRadius = 2.2 + (1 - progress) * 1.6;

    for (var i = 0; i < _burstDots.length; i++) {
      final (cosA, sinA, isPale) = _burstDots[i];
      final p = Offset(center.dx + cosA * spread, center.dy + sinA * spread);
      _dotPaint.color = (isPale ? AppColors.goldPale : AppColors.goldLight)
          .withValues(alpha: dotAlpha);
      canvas.drawCircle(p, dotRadius, _dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
