import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/badge_model.dart';
import '../../../../providers/badge_celebration_provider.dart';

class BadgeCelebrationHost extends ConsumerWidget {
  const BadgeCelebrationHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final celebration = ref.watch(badgeCelebrationProvider);
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
    required this.onComplete,
  });

  final BadgeDefinition badge;
  final VoidCallback onComplete;

  @override
  State<_BadgeCelebrationOverlay> createState() =>
      _BadgeCelebrationOverlayState();
}

class _BadgeCelebrationOverlayState extends State<_BadgeCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: ColoredBox(
        color: AppColors.emeraldDeep.withValues(alpha: 0.94),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final easeOut = Curves.easeOutCubic.transform(
              (t * 1.3).clamp(0.0, 1.0),
            );
            final iconScale = 0.7 + (easeOut * 0.45);
            final glow = (math.sin(t * math.pi * 6) * 0.5 + 0.5) * 0.8;

            return Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.62,
                    width: double.infinity,
                    child: CustomPaint(painter: _BurstPainter(progress: t)),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Badge Unlocked',
                          style: AppTextStyles.headlineLarge(context).copyWith(
                            color: AppColors.goldPale,
                            letterSpacing: 0.8,
                            shadows: const [],
                            decoration: TextDecoration.none,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Transform.scale(
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
                            child: Icon(
                              widget.badge.icon,
                              size: 64.r,
                              color: AppColors.emeraldDeep,
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displayMedium(context).copyWith(
                            color: AppColors.textPrimary,
                            height: 1.05,
                            shadows: const [],
                            decoration: TextDecoration.none,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          desc,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge(
                            context,
                          ).copyWith(
                            color: AppColors.textSecondary,
                            shadows: const [],
                            decoration: TextDecoration.none,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          'Tap to continue',
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(
                            color: AppColors.goldPale,
                            shadows: const [],
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
      default:
        return badge.description;
    }
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    final maxRadius = size.shortestSide * 0.48;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = AppColors.goldPale.withValues(alpha: (1 - progress) * 0.55);
    canvas.drawCircle(center, maxRadius * (0.35 + progress * 0.65), ringPaint);

    const rays = 18;
    for (var i = 0; i < rays; i++) {
      final angle = (math.pi * 2 * i) / rays;
      final length = maxRadius * (0.25 + 0.65 * progress);
      final start = Offset(
        center.dx + math.cos(angle) * maxRadius * 0.16,
        center.dy + math.sin(angle) * maxRadius * 0.16,
      );
      final end = Offset(
        center.dx + math.cos(angle) * length,
        center.dy + math.sin(angle) * length,
      );
      final rayPaint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2
        ..color = (i.isEven ? AppColors.goldLight : AppColors.cream).withValues(
          alpha: (1 - progress) * 0.7,
        );
      canvas.drawLine(start, end, rayPaint);
    }

    final rng = math.Random(37);
    for (var i = 0; i < 28; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final spread = maxRadius * (0.35 + progress * 0.85);
      final dx = math.cos(angle) * spread;
      final dy = math.sin(angle) * spread;
      final p = Offset(center.dx + dx, center.dy + dy);
      final dot = Paint()
        ..style = PaintingStyle.fill
        ..color = (i % 3 == 0 ? AppColors.goldPale : AppColors.goldLight)
            .withValues(alpha: (1 - progress).clamp(0.0, 1.0));
      canvas.drawCircle(p, 2.2 + (1 - progress) * 1.6, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
