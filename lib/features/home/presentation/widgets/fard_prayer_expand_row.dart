import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// A horizontal row of prayer circles for an expandable numeric amal field.
///
/// Each circle represents one of the five daily prayers and can be toggled on
/// and off independently. On Fridays the second slot (Dhuhr) is relabelled as
/// Jummah. The persisted field value stays a simple count (number of lit
/// circles); the specific lit positions are tracked separately by the caller.
class FardPrayerExpandRow extends StatelessWidget {
  const FardPrayerExpandRow({
    super.key,
    required this.selectedIndices,
    required this.onToggleIndex,
    this.slotCount = 5,
    this.readOnly = false,
  });

  /// Indices (0-based) of the currently lit prayer circles.
  final Set<int> selectedIndices;

  /// Called with the tapped circle index; the caller flips that prayer.
  final ValueChanged<int> onToggleIndex;

  /// Number of prayer circles to render (capped at the five daily prayers).
  final int slotCount;
  final bool readOnly;

  /// Extra invisible tap area added around each circle on every side.
  static const double _hitSlop = 10;

  /// Canonical prayer keys in daily order.
  static const List<String> _prayerKeys = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  /// Material icons per prayer slot (Jummah reuses a mosque glyph).
  static const Map<String, IconData> _prayerIcons = {
    'fajr': Icons.wb_twilight,
    'dhuhr': Icons.wb_sunny_outlined,
    'jummah': Icons.mosque_outlined,
    'asr': Icons.wb_cloudy_outlined,
    'maghrib': Icons.nights_stay_outlined,
    'isha': Icons.dark_mode_outlined,
  };

  String _prayerName(AppLocalizations l10n, String key) {
    switch (key) {
      case 'fajr':
        return l10n.prayerFajr;
      case 'dhuhr':
        return l10n.prayerDhuhr;
      case 'jummah':
        return l10n.prayerJummah;
      case 'asr':
        return l10n.prayerAsr;
      case 'maghrib':
        return l10n.prayerMaghrib;
      case 'isha':
        return l10n.prayerIsha;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFriday = IslamicDateService.isCurrentPrayerDayFriday();
    final slots = slotCount.clamp(1, _prayerKeys.length);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, thickness: 0.8, color: AppColors.cardBorder),
        Padding(
          padding: EdgeInsets.fromLTRB(0.w, 10.h, 0.w, 0.h),
          child: Row(
            children: List.generate(slots, (index) {
              final key = index == 1 && isFriday
                  ? 'jummah'
                  : _prayerKeys[index];
              final isChecked = selectedIndices.contains(index);
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isChecked,
                  label: _prayerName(l10n, key),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      _TapScale(
                        onTap: readOnly
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                onToggleIndex(index);
                              },
                        hitSlop: _hitSlop,
                        child: _PrayerCircle(
                          isChecked: isChecked,
                          icon: _prayerIcons[key] ?? Icons.check,
                          label: _prayerName(l10n, key),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// Wraps [child] with an enlarged tap target and a subtle press-scale
/// animation, giving toggle taps a more tactile, responsive feel.
/// Wraps [child] with an enlarged tap target and a subtle press-scale
/// animation, giving toggle taps a more tactile, responsive feel.
///
/// The extra tap area is an invisible overlay (via [Positioned.fill] with
/// negative insets) so it never affects the layout size of [child].
class _TapScale extends StatefulWidget {
  const _TapScale({
    required this.child,
    required this.onTap,
    required this.hitSlop,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double hitSlop;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedScale(
          scale: _pressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
        Positioned.fill(
          left: -widget.hitSlop.w,
          right: -widget.hitSlop.w,
          top: -widget.hitSlop.h,
          bottom: -widget.hitSlop.h,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: widget.onTap,
          ),
        ),
      ],
    );
  }
}

/// A prayer circle whose fill sweeps in like a radial progress indicator
/// (0% to 100%, clockwise from the top) when toggled on, and sweeps back
/// out the same way when toggled off.
class _PrayerCircle extends StatefulWidget {
  const _PrayerCircle({
    required this.isChecked,
    required this.icon,
    required this.label,
  });

  final bool isChecked;
  final IconData icon;
  final String label;

  @override
  State<_PrayerCircle> createState() => _PrayerCircleState();
}

class _PrayerCircleState extends State<_PrayerCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: widget.isChecked ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _PrayerCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChecked != oldWidget.isChecked) {
      if (widget.isChecked) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.bodySmall(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;
            return SizedBox(
              width: 36.r,
              height: 36.r,
              child: CustomPaint(
                painter: _RadialFillPainter(
                  progress: progress,
                  fillColor: AppColors.gold,
                  borderColor: AppColors.cardBorder,
                  strokeWidth: 1.5.r,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: progress > 0.5
                        ? Icon(
                            Icons.check,
                            key: const ValueKey(true),
                            color: AppColors.emeraldDeep,
                            size: 18.r,
                          )
                        : Icon(
                            widget.icon,
                            key: const ValueKey(false),
                            color: AppColors.textMuted,
                            size: 14.r,
                          ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 4.h),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;
            return Text(
              widget.label,
              style: labelStyle.copyWith(
                fontSize: 9.sp,
                color: Color.lerp(
                  AppColors.textMuted,
                  AppColors.gold,
                  progress,
                ),
                fontWeight: progress > 0.5
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
      ],
    );
  }
}

/// Paints a circular border plus a pie-style sweep that fills clockwise
/// from the top as [progress] goes from 0 to 1, like a radial progress ring
/// completing into a solid disc.
class _RadialFillPainter extends CustomPainter {
  _RadialFillPainter({
    required this.progress,
    required this.fillColor,
    required this.borderColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color fillColor;
  final Color borderColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Border ring: colour transitions alongside the fill so the outline
    // finishes turning gold exactly as the sweep completes.
    final borderPaint = Paint()
      ..color = Color.lerp(borderColor, fillColor, progress)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, borderPaint);

    if (progress <= 0) return;

    // Pie-style fill sweeping clockwise from 12 o'clock.
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;
    final fillRadius = radius - strokeWidth / 2;
    final fillRect = Rect.fromCircle(center: center, radius: fillRadius);

    canvas.drawArc(fillRect, startAngle, sweepAngle, true, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _RadialFillPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}
