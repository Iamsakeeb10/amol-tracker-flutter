import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';

class DhikrBeadButton extends StatefulWidget {
  const DhikrBeadButton({
    super.key,
    required this.onTap,
    required this.enabled,
    required this.justCompleted,
  });

  final VoidCallback onTap;
  final bool enabled;
  final bool justCompleted;

  @override
  State<DhikrBeadButton> createState() => _DhikrBeadButtonState();
}

class _DhikrBeadButtonState extends State<DhikrBeadButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _registerTap() {
    if (!widget.enabled) return;
    widget.onTap();
    _pulse();
  }

  void _pulse() {
    _controller.forward(from: 0).then((_) {
      if (mounted) _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.justCompleted ? AppColors.success : AppColors.gold;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _registerTap(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(scale: _scale.value, child: child);
        },
        child: Container(
          width: 220.r,
          height: 220.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                glowColor.withValues(alpha: 0.35),
                AppColors.emeraldMid,
                AppColors.emeraldDeep,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            border: Border.all(
              color: glowColor.withValues(alpha: widget.enabled ? 0.85 : 0.35),
              width: 2.r,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.25),
                blurRadius: 28.r,
                spreadRadius: 2.r,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.touch_app_rounded,
            size: 56.r,
            color: glowColor.withValues(alpha: widget.enabled ? 1 : 0.45),
          ),
        ),
      ),
    );
  }
}

class DhikrTapHint extends StatelessWidget {
  const DhikrTapHint({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.bodySmall(context).copyWith(
        color: AppColors.textSecondary,
        fontSize: 12.sp,
      ),
    );
  }
}
