import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const QiblahApp());
}

class QiblahApp extends StatelessWidget {
  const QiblahApp({super.key});

  static const _bg = Color(0xFF0D1F14);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qiblah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1B6B47),
          secondary: Color(0xFFD4A843),
          surface: _bg,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1B6B47),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      home: const QiblahScreen(),
    );
  }
}

// ── Screen state machine ──────────────────────────────────────────────────────

enum _State { loading, permissionDenied, permissionPermanent, ready }

class QiblahScreen extends StatefulWidget {
  const QiblahScreen({super.key});
  @override
  State<QiblahScreen> createState() => _QiblahScreenState();
}

class _QiblahScreenState extends State<QiblahScreen> {
  _State _state = _State.loading;
  double? _qiblahBearing;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _state = _State.loading);
    final status = await Permission.location.status;
    if (status.isPermanentlyDenied) {
      setState(() => _state = _State.permissionPermanent);
      return;
    }
    if (!status.isGranted) {
      final result = await Permission.location.request();
      if (result.isPermanentlyDenied) {
        setState(() => _state = _State.permissionPermanent);
        return;
      }
      if (!result.isGranted) {
        setState(() => _state = _State.permissionDenied);
        return;
      }
    }
    await _locate();
  }

  Future<void> _locate() async {
    setState(() => _state = _State.loading);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final bearing = Qibla.qibla(Coordinates(pos.latitude, pos.longitude));
      setState(() {
        _qiblahBearing = bearing;
        _state = _State.ready;
      });
    } catch (_) {
      setState(() => _state = _State.permissionDenied);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _State.loading:
        return const Center(child: CircularProgressIndicator());

      case _State.permissionDenied:
        return _Gate(
          icon: Icons.location_searching_rounded,
          label: 'Grant Location Permission',
          onTap: _bootstrap,
        );

      case _State.permissionPermanent:
        return _Gate(
          icon: Icons.location_off_rounded,
          label: 'Open Settings',
          onTap: openAppSettings,
        );

      case _State.ready:
        return _CompassView(qiblahBearing: _qiblahBearing!);
    }
  }
}

// ── Compass view (stateful for low-pass filter) ───────────────────────────────

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
          return const Center(child: CircularProgressIndicator());
        }
        final heading = _smooth(raw);
        final needleRad = (widget.qiblahBearing - heading) * (math.pi / 180);

        double offset = (widget.qiblahBearing - heading) % 360;
        if (offset > 180) offset -= 360;
        final isFacing = offset.abs() < 5.0;

        return _Dial(needleRad: needleRad, isFacing: isFacing);
      },
    );
  }
}

// ── Dial ─────────────────────────────────────────────────────────────────────

class _Dial extends StatelessWidget {
  const _Dial({required this.needleRad, required this.isFacing});
  final double needleRad;
  final bool isFacing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: LayoutBuilder(builder: (context, box) {
        final size = math.min(box.maxWidth, box.maxHeight) * 0.82;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Outer glow ring ──
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isFacing
                        ? cs.secondary.withValues(alpha: 0.8)
                        : cs.primary.withValues(alpha: 0.4),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isFacing
                          ? cs.secondary.withValues(alpha: 0.25)
                          : cs.primary.withValues(alpha: 0.10),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),

              // ── Tick marks + rings ──
              CustomPaint(
                size: Size(size, size),
                painter: _DialPainter(
                  ringColor: cs.primary.withValues(alpha: 0.12),
                  majorTickColor: Colors.white.withValues(alpha: 0.35),
                  minorTickColor: Colors.white.withValues(alpha: 0.12),
                ),
              ),

              // ── Cardinal N/E/S/W ──
              _Cardinals(size: size),

              // ── Rotating needle ──
              Transform.rotate(
                angle: needleRad,
                child: _Needle(size: size, isFacing: isFacing),
              ),

              // ── Centre dot ──
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFacing ? cs.secondary : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: (isFacing ? cs.secondary : Colors.white)
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

// ── Needle ────────────────────────────────────────────────────────────────────

class _Needle extends StatelessWidget {
  const _Needle({required this.size, required this.isFacing});
  final double size;
  final bool isFacing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isFacing ? cs.secondary : cs.primary;
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
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                CustomPaint(
                  size: const Size(10, 8),
                  painter: _ArrowPainter(
                    color: Colors.white.withValues(alpha: 0.18),
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

// ── Cardinals ─────────────────────────────────────────────────────────────────

class _Cardinals extends StatelessWidget {
  const _Cardinals({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    const dirs = ['N', 'E', 'S', 'W'];
    const angles = [0.0, math.pi / 2, math.pi, -math.pi / 2];
    // Place labels between the innermost (0.60) and middle (0.75) decorative
    // rings — well clear of the tick zone which starts at 0.86
    final r = size * 0.5 * 0.80;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(4, (i) {
          final dx = r * math.sin(angles[i]);
          final dy = -r * math.cos(angles[i]);
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Text(
              dirs[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dirs[i] == 'N'
                    ? Colors.redAccent
                    : Colors.white.withValues(alpha: 0.55),
                fontSize: size * 0.065, // scales with dial size
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

// ── Painters ──────────────────────────────────────────────────────────────────

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

// ── Gate (permission / error fallback) ───────────────────────────────────────

class _Gate extends StatelessWidget {
  const _Gate({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: cs.primary),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.my_location_rounded, size: 18),
                label: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}