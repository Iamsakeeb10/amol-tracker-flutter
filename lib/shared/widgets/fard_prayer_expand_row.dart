import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';


import '../../core/services/local_storage_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../l10n/app_localizations.dart';

/// A horizontal row of prayer circles for an expandable numeric amal field.
///
/// Each circle represents one of the five daily prayers and can be toggled on
/// and off independently. On Fridays the second slot (Dhuhr) is relabelled as
/// Jummah. The persisted field value stays a simple count (number of lit
/// circles); the specific lit positions are tracked separately by the caller.
///
/// A one-time tutorial coach mark highlights the first prayer circle when the
/// row is first expanded, teaching the user to tap a circle to toggle it.
class FardPrayerExpandRow extends StatefulWidget {
  const FardPrayerExpandRow({
    super.key,
    required this.selectedIndices,
    required this.onToggleIndex,
    required this.isFriday,
    this.slotCount = 5,
    this.readOnly = false,
  });

  /// Exposed to the parent so it can suppress `TapRegion.onTapOutside` while
  /// the tutorial overlay is visible (tapping the overlay would otherwise
  /// collapse the row because the overlay lives outside the TapRegion subtree).
  static final ValueNotifier<bool> tutorialActive = ValueNotifier<bool>(false);

  /// Indices (0-based) of the currently lit prayer circles.
  final Set<int> selectedIndices;

  /// Called with the tapped circle index; the caller flips that prayer.
  final ValueChanged<int> onToggleIndex;

  /// Number of prayer circles to render (capped at the five daily prayers).
  final int slotCount;
  final bool readOnly;
  final bool isFriday;

  @override
  State<FardPrayerExpandRow> createState() => FardPrayerExpandRowState();
}

class FardPrayerExpandRowState extends State<FardPrayerExpandRow> {
  static const String _tutorialShownKey = 'fard_prayer_tutorial_shown';

  /// In-memory flag so the tutorial is never re-shown within the same session,
  /// even if the Hive write hasn't flushed yet.
  static bool _tutorialShownThisSession = false;

  /// Key attached to the first prayer circle icon so the coach mark can target it.
  final GlobalKey _firstCircleIconKey = GlobalKey();

  TutorialCoachMark? _coachMark;

  @override
  void initState() {
    super.initState();
    if (!widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialIfNew());
    }
  }

  void _showTutorialIfNew() {
    if (_tutorialShownThisSession) return;
    final alreadyShown = LocalStorageService.getPref(_tutorialShownKey, false);
    if (alreadyShown) {
      _tutorialShownThisSession = true;
      return;
    }
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    _coachMark = TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: 'prayer_circle_tap',
          keyTarget: _firstCircleIconKey,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.tutorialPrayerTapHint,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
          enableTargetTab: true,
          enableOverlayTab: true,
        ),
      ],
      colorShadow: Colors.black54,
      opacityShadow: 0.7,
      paddingFocus: 4,
      textSkip: l10n.tutorialGotIt,
      hideSkip: false,
      onFinish: _onTutorialDone,
      onSkip: () {
        _onTutorialDone();
        return true;
      },
      onClickTarget: (_) {
        _onTutorialDone();
      },
      onClickOverlay: (_) {
        _onTutorialDone();
      },
    );

    FardPrayerExpandRow.tutorialActive.value = true;
    _coachMark?.show(context: context);
  }

  void _onTutorialDone() {
    _tutorialShownThisSession = true;
    FardPrayerExpandRow.tutorialActive.value = false;
    LocalStorageService.setPref(_tutorialShownKey, true);
  }

  @override
  void dispose() {
    _coachMark?.removeOverlayEntry();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFriday = widget.isFriday;
    final slots = widget.slotCount.clamp(1, _prayerKeys.length);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, thickness: 0.8, color: AppColors.cardBorder),
        Padding(
          padding: EdgeInsets.fromLTRB(0.w, 10.h, 0.w, 0.h),
          child: Row(
            children: List.generate(slots, (index) {
              final key = index == 1 && isFriday ? 'jummah' : _prayerKeys[index];
              final isChecked = widget.selectedIndices.contains(index);
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
                        onTap: widget.readOnly
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                widget.onToggleIndex(index);
                              },
                        hitSlop: _hitSlop,
                        child: _PrayerCircle(
                          isChecked: isChecked,
                          icon: _prayerIcons[key] ?? Icons.check,
                          label: _prayerName(l10n, key),
                          circleKey: index == 0 ? _firstCircleIconKey : null,
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

/// Extra invisible tap area added around each circle on every side.
const double _hitSlop = 10;

/// Canonical prayer keys in daily order.
const List<String> _prayerKeys = [
  'fajr',
  'dhuhr',
  'asr',
  'maghrib',
  'isha',
];

/// Material icons per prayer slot (Jummah reuses a mosque glyph).
const Map<String, IconData> _prayerIcons = {
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

/// A prayer circle that "blooms" in — the fill grows radially outward from
/// the center to full size with a slight overshoot bounce on completion —
/// rather than sweeping like a clock hand. Reverses the same way on untoggle.
class _PrayerCircle extends StatefulWidget {
  const _PrayerCircle({
    required this.isChecked,
    required this.icon,
    required this.label,
    this.circleKey,
  });

  final bool isChecked;
  final IconData icon;
  final String label;

  /// Key attached to the painted circle SizedBox for coach mark targeting.
  final GlobalKey? circleKey;

  @override
  State<_PrayerCircle> createState() => _PrayerCircleState();
}

class _PrayerCircleState extends State<_PrayerCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bloom;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: widget.isChecked ? 1 : 0,
    );
    _bloom = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
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
          animation: _bloom,
          builder: (context, _) {
            final linear = _controller.value.clamp(0.0, 1.0);
            return SizedBox(
              key: widget.circleKey,
              width: 36.r,
              height: 36.r,
              child: CustomPaint(
                painter: _BloomFillPainter(
                  bloom: _bloom.value,
                  fillColor: AppColors.gold,
                  borderColor: AppColors.cardBorder,
                  strokeWidth: 1.5.r,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 120),
                    child: linear > 0.5
                        ? TweenAnimationBuilder<double>(
                            key: const ValueKey(true),
                            tween: Tween(begin: 0.4, end: 1.0),
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutBack,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: Icon(
                              Icons.check,
                              color: AppColors.emeraldDeep,
                              size: 18.r,
                            ),
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
          animation: _bloom,
          builder: (context, _) {
            final linear = _controller.value.clamp(0.0, 1.0);
            return Text(
              widget.label,
              style: labelStyle.copyWith(
                fontSize: 9.sp,
                color: Color.lerp(AppColors.textMuted, AppColors.gold, linear),
                fontWeight: linear > 0.5 ? FontWeight.w600 : FontWeight.normal,
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

class _BloomFillPainter extends CustomPainter {
  _BloomFillPainter({
    required this.bloom,
    required this.fillColor,
    required this.borderColor,
    required this.strokeWidth,
  });

  final double bloom;
  final Color fillColor;
  final Color borderColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringRadius = (size.shortestSide - strokeWidth) / 2;
    final linear = bloom.clamp(0.0, 1.0);

    final borderPaint = Paint()
      ..color = Color.lerp(borderColor, fillColor, linear)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, ringRadius, borderPaint);

    if (bloom <= 0) return;

    final fillRadius = (ringRadius - strokeWidth / 2) * bloom.clamp(0.0, 1.06);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, fillRadius, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _BloomFillPainter oldDelegate) {
    return oldDelegate.bloom != bloom ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}
