import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/bottom_tab_back_button.dart';

enum _State { loading, permissionDenied, permissionPermanent, ready }

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  _State _state = _State.loading;
  double? _qiblahBearing;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenViewed('qibla');
    AnalyticsService.instance.logQiblaOpened();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final status = await Permission.location.status;
    if (status.isPermanentlyDenied) {
      if (mounted) setState(() => _state = _State.permissionPermanent);
      return;
    }
    if (!status.isGranted) {
      final result = await Permission.location.request();
      if (result.isPermanentlyDenied) {
        if (mounted) setState(() => _state = _State.permissionPermanent);
        return;
      }
      if (!result.isGranted) {
        if (mounted) setState(() => _state = _State.permissionDenied);
        return;
      }
    }
    await _locate();
  }

  Future<void> _locate() async {
    try {
      // 1. Try last known position for instant load
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() {
          _qiblahBearing = Qibla.qibla(Coordinates(lastPos.latitude, lastPos.longitude));
          _state = _State.ready;
        });
      }

      // If we still don't have a position, show loader
      if (lastPos == null && mounted) {
        setState(() => _state = _State.loading);
      }

      // 2. Fetch current position for accuracy
      final currentPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      
      if (mounted) {
        setState(() {
          _qiblahBearing = Qibla.qibla(Coordinates(currentPos.latitude, currentPos.longitude));
          _state = _State.ready;
        });
      }
    } catch (_) {
      if (_qiblahBearing == null && mounted) {
        setState(() => _state = _State.permissionDenied);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        toolbarHeight: 52.h,
        leading: const BottomTabBackButton(),
        title: Text(
          l10n.qiblaTitle,
          style: AppTextStyles.headlineMedium(context).copyWith(
            fontSize: 17.5.sp,
            fontWeight: FontWeight.w600,
            height: 0,
          ),
        ),
      ),
      body: SafeArea(child: _buildBody(l10n)),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    switch (_state) {
      case _State.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        );

      case _State.permissionDenied:
        return _Gate(
          icon: Icons.location_searching_rounded,
          label: l10n.qiblaGrantLocationPermission,
          onTap: _bootstrap,
        );

      case _State.permissionPermanent:
        return _Gate(
          icon: Icons.location_off_rounded,
          label: l10n.qiblaOpenSettings,
          onTap: openAppSettings,
        );

      case _State.ready:
        return _CompassView(qiblahBearing: _qiblahBearing!);
    }
  }
}

class _CompassView extends StatefulWidget {
  const _CompassView({required this.qiblahBearing});
  final double qiblahBearing;
  @override
  State<_CompassView> createState() => _CompassViewState();
}

class _CompassViewState extends State<_CompassView> {
  double _smoothed = 0;
  static const _alpha = 0.15;

  double _smooth(double raw) {
    double delta = raw - _smoothed;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    _smoothed = (_smoothed + _alpha * delta) % 360;
    if (_smoothed < 0) _smoothed += 360;
    return _smoothed;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        final raw = snapshot.data?.heading;
        if (raw == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );
        }
        final heading = _smooth(raw);
        final needleRad = (widget.qiblahBearing - heading) * (math.pi / 180);
        final dialRad = -heading * (math.pi / 180);

        double offset = (widget.qiblahBearing - heading) % 360;
        if (offset > 180) offset -= 360;
        final isFacing = offset.abs() < 5.0;

        return _Dial(needleRad: needleRad, dialRad: dialRad, isFacing: isFacing);
      },
    );
  }
}

class _Dial extends StatelessWidget {
  const _Dial({required this.needleRad, required this.dialRad, required this.isFacing});
  final double needleRad;
  final double dialRad;
  final bool isFacing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(builder: (context, box) {
        final size = math.min(box.maxWidth, box.maxHeight) * 0.82;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isFacing
                        ? AppColors.success.withValues(alpha: 0.85)
                        : AppColors.goldLight.withValues(alpha: 0.55),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isFacing
                          ? AppColors.success.withValues(alpha: 0.28)
                          : AppColors.gold.withValues(alpha: 0.16),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),

              // Rotating compass rose (tick marks + N/E/S/W labels)
              Transform.rotate(
                angle: dialRad,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _DialPainter(
                    ringColor: AppColors.gold.withValues(alpha: 0.20),
                    majorTickColor: AppColors.goldLight.withValues(alpha: 0.55),
                    minorTickColor: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
              ),

              // Cardinal N/E/S/W — positions orbit with heading, text always upright
              _Cardinals(size: size, dialRad: dialRad),

              // Rotating needle (always points at Qibla)
              Transform.rotate(
                angle: needleRad,
                child: _Needle(size: size, isFacing: isFacing),
              ),

              // Centre dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFacing ? AppColors.success : AppColors.goldLight,
                  boxShadow: [
                    BoxShadow(
                      color: (isFacing ? AppColors.success : AppColors.gold)
                          .withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Needle extends StatelessWidget {
  const _Needle({required this.size, required this.isFacing});
  final double size;
  final bool isFacing;

  @override
  Widget build(BuildContext context) {
    final color = isFacing ? AppColors.success : AppColors.gold;
    final tipReach = size * 0.33;
    final tailReach = size * 0.18;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tip (Kaaba side)
          Positioned(
            top: size / 2 - tipReach,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🕋', style: TextStyle(fontSize: 15)),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 3.5,
                  height: (tipReach - 18).clamp(4, double.infinity),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color, color.withValues(alpha: 0.2)],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tail
          Positioned(
            bottom: size / 2 - tailReach,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 3.5,
                  height: tailReach - 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: AppColors.goldPale.withValues(alpha: 0.25),
                  ),
                ),
                CustomPaint(
                  size: const Size(10, 8),
                  painter: _ArrowPainter(
                    color: AppColors.goldPale.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cardinals extends StatelessWidget {
  const _Cardinals({required this.size, required this.dialRad});
  final double size;
  final double dialRad;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dirs = [
      l10n.qiblaNorth,
      l10n.qiblaEast,
      l10n.qiblaSouth,
      l10n.qiblaWest,
    ];
    // Geographic world angles for each direction
    const worldAngles = [0.0, math.pi / 2, math.pi, -math.pi / 2];
    final r = size * 0.5 * 0.80;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(4, (i) {
          // Compute screen position from world angle + dial rotation
          // Text itself has zero rotation — always perfectly upright and readable
          final screenAngle = worldAngles[i] + dialRad;
          final dx = r * math.sin(screenAngle);
          final dy = -r * math.cos(screenAngle);
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Text(
              dirs[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: i == 0 // Index 0 is North
                    ? AppColors.danger
                    : AppColors.goldLight.withValues(alpha: 0.6),
                fontSize: size * 0.065,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.ringColor,
    required this.majorTickColor,
    required this.minorTickColor,
  });
  final Color ringColor;
  final Color majorTickColor;
  final Color minorTickColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final rp = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final ratio in [0.60, 0.75, 0.88]) {
      canvas.drawCircle(c, r * ratio, rp);
    }

    for (int i = 0; i < 360; i += 5) {
      final isMajor = i % 45 == 0;
      final isMid = i % 15 == 0;
      final angle = i * math.pi / 180;
      final outer = r * 0.96;
      final inner = r * (isMajor ? 0.89 : isMid ? 0.91 : 0.94);
      canvas.drawLine(
        c + Offset(math.sin(angle) * inner, -math.cos(angle) * inner),
        c + Offset(math.sin(angle) * outer, -math.cos(angle) * outer),
        Paint()
          ..color = isMajor ? majorTickColor : minorTickColor
          ..strokeWidth = isMajor ? 1.5 : 0.8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(size.width / 2, size.height)
        ..lineTo(0, 0)
        ..lineTo(size.width, 0)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _Gate extends StatelessWidget {
  const _Gate({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.gold),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.my_location_rounded, size: 18),
                label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}