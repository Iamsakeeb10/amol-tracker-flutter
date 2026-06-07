import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/lms_level_config.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/device_tier_provider.dart';
import '../../../../providers/lms_level_celebration_provider.dart';
import '../../../../shared/widgets/celebration_burst.dart';

class LmsLevelUpHost extends ConsumerWidget {
  const LmsLevelUpHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final celebration = ref.watch(lmsLevelCelebrationProvider);
    final reduceMotion = ref.watch(reduceMotionProvider);
    final levelIndex = celebration.currentLevelIndex;
    LmsLevelTier? tier;
    if (levelIndex != null && levelIndex < kLmsLevelTiers.length) {
      tier = kLmsLevelTiers[levelIndex];
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (tier != null)
          _LmsLevelUpOverlay(
            tier: tier,
            reduceMotion: reduceMotion,
            onComplete: () =>
                ref.read(lmsLevelCelebrationProvider.notifier).completeCurrent(),
          ),
      ],
    );
  }
}

class _LmsLevelUpOverlay extends StatefulWidget {
  const _LmsLevelUpOverlay({
    required this.tier,
    required this.reduceMotion,
    required this.onComplete,
  });

  final LmsLevelTier tier;
  final bool reduceMotion;
  final VoidCallback onComplete;

  @override
  State<_LmsLevelUpOverlay> createState() => _LmsLevelUpOverlayState();
}

class _LmsLevelUpOverlayState extends State<_LmsLevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 2200),
    );
    if (widget.reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _iconForTier(LmsLevelTier tier) {
    return switch (tier.iconName) {
      'menu_book' => Icons.menu_book_rounded,
      'auto_stories' => Icons.auto_stories_rounded,
      'school' => Icons.school_rounded,
      'workspace_premium' => Icons.workspace_premium_rounded,
      _ => Icons.eco_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = lmsLevelTitle(widget.tier, l10n);

    return Material(
      color: AppColors.emeraldDeep.withValues(alpha: 0.92),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onComplete,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: CelebrationBurstPainter(progress: progress),
                  size: Size.infinite,
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 0.6 + progress * 0.4,
                          child: Container(
                            width: 88.r,
                            height: 88.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.gold.withValues(alpha: 0.2),
                              border: Border.all(color: AppColors.gold, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              _iconForTier(widget.tier),
                              size: 40.r,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          l10n.lmsLevelUpTitle,
                          style: AppTextStyles.headlineMedium(context).copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displayMedium(context).copyWith(
                            color: AppColors.cream,
                            fontSize: 22.sp,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          l10n.lmsLevelUpTapToContinue,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textMuted,
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
}
