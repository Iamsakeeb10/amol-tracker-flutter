import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';

/// Wraps a child widget with swipe-to-toggle functionality.
///
/// Swiping right reveals a green "done" background; swiping left reveals a
/// grey "undo" background. Releasing past the threshold triggers the toggle.
/// The swipe only works when [enabled] is true and the child isn't already
/// in a dismissed state matching the swipe direction.
class SwipeToToggle extends StatefulWidget {
  const SwipeToToggle({
    super.key,
    required this.child,
    required this.isDone,
    required this.onToggle,
    this.enabled = true,
  });

  final Widget child;
  final bool isDone;
  final VoidCallback onToggle;
  final bool enabled;

  @override
  State<SwipeToToggle> createState() => _SwipeToToggleState();
}

class _SwipeToToggleState extends State<SwipeToToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dragAnimation;
  double _dragExtent = 0;
  bool _needsConfirm = false;

  static const _threshold = 80.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _dragAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.enabled) return;
    _needsConfirm = false;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    final delta = details.primaryDelta ?? 0;

    // Prevent swiping in the direction that doesn't make sense:
    // - If already done, don't swipe right (would try to "mark done" again)
    // - If not done, don't swipe left (would try to "undo" nothing)
    if (!widget.isDone && delta < 0) return;
    if (widget.isDone && delta > 0) return;

    setState(() {
      _dragExtent += delta;
      _dragExtent = _dragExtent.clamp(-_threshold * 1.5, _threshold * 1.5);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enabled) return;

    final velocity = details.primaryVelocity ?? 0;
    final confirm =
        _dragExtent.abs() > _threshold || velocity.abs() > 500;

    if (confirm && _dragExtent.abs() > 10) {
      _needsConfirm = true;
      HapticFeedback.mediumImpact();
      widget.onToggle();
    }

    _animateBack();
  }

  void _animateBack() {
    _dragAnimation = Tween<double>(begin: _dragExtent, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller
      ..reset()
      ..forward().then((_) {
        if (mounted) {
          setState(() {
            _dragExtent = 0;
            _needsConfirm = false;
          });
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    // Determine which direction swipe is allowed
    final canSwipeRight = !widget.isDone; // swipe right = mark done
    final canSwipeLeft = widget.isDone; // swipe left = undo

    // Effective drag extent considering direction constraints
    double effectiveDrag = _dragExtent;
    if (!canSwipeRight && effectiveDrag > 0) effectiveDrag = 0;
    if (!canSwipeLeft && effectiveDrag < 0) effectiveDrag = 0;

    final progress = (effectiveDrag / _threshold).clamp(-1.0, 1.0);
    final showDoneBg = effectiveDrag > 10;
    final showUndoBg = effectiveDrag < -10;

    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          // Background revealed by swipe
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: showDoneBg
                    ? AppColors.success.withValues(alpha: progress.abs() * 0.25)
                    : showUndoBg
                        ? AppColors.textMuted.withValues(
                            alpha: progress.abs() * 0.2,
                          )
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Row(
                mainAxisAlignment: showDoneBg
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
                children: [
                  if (showDoneBg)
                    Padding(
                      padding: EdgeInsets.only(left: 16.w),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success.withValues(
                          alpha: progress.abs().clamp(0.3, 1.0),
                        ),
                        size: 22.r,
                      ),
                    ),
                  if (showUndoBg)
                    Padding(
                      padding: EdgeInsets.only(right: 16.w),
                      child: Icon(
                        Icons.undo,
                        color: AppColors.textSecondary.withValues(
                          alpha: progress.abs().clamp(0.3, 1.0),
                        ),
                        size: 22.r,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Foreground content that slides
          AnimatedBuilder(
            animation: _needsConfirm ? _dragAnimation : const AlwaysStoppedAnimation(0),
            builder: (context, child) {
              final offset = _needsConfirm ? _dragAnimation.value : effectiveDrag;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
