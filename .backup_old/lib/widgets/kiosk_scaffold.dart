import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Root scaffold for every kiosk screen — Cyber-Brutalist Maximalist grid
/// + continuous background telemetry motion.
///
/// Preserves [KioskScaffold.gridKey], [overscan], [background], and
/// [showGrid] while running a lightweight GPU-friendly animation loop.
class KioskScaffold extends StatefulWidget {
  const KioskScaffold({
    super.key,
    required this.child,
    this.background,
    this.overscan = 0.0,
    this.showGrid = true,
  }) : assert(
         overscan >= 0 && overscan < 0.5,
         'overscan must be a sane fraction of the shortest side',
       );

  /// The screen content (feature screen body).
  final Widget child;

  /// Optional decorative layer painted behind the content (attract mode).
  final Widget? background;

  /// Overscan-safe inset as a fraction of the shortest side.
  /// 0.0 on phone; 0.05 for TV.
  final double overscan;

  /// Toggles the animated cyber-grid texture.
  final bool showGrid;

  /// Stable key for the texture layer so tests can prove it paints.
  static const gridKey = Key('kiosk_dot_grid');

  @override
  State<KioskScaffold> createState() => _KioskScaffoldState();
}

class _KioskScaffoldState extends State<KioskScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.showGrid)
            IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  key: KioskScaffold.gridKey,
                  painter: _CyberMaxGridPainter(phase: _ambientController),
                ),
              ),
            ),
          if (widget.background != null)
            IgnorePointer(child: widget.background!),
          LayoutBuilder(
            builder: (context, constraints) {
              final inset = widget.overscan * constraints.biggest.shortestSide;
              return SafeArea(
                minimum: EdgeInsets.all(inset),
                child: widget.child,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Cyber-Brutalist kinetic grid + sweeping scan beam + node points.
///
/// Uses a single `drawPoints` call for nodes and light lines/scan beam—no
/// `BackdropFilter` or `saveLayer` overhead on kiosk/TV GPUs.
class _CyberMaxGridPainter extends CustomPainter {
  _CyberMaxGridPainter({required this.phase}) : super(repaint: phase);

  final Animation<double> phase;

  @override
  void paint(Canvas canvas, Size size) {
    final t = phase.value;
    const step = AppSpacing.xl * 1.5; // 36.0
    final driftX = (t * step) % step;
    final driftY = ((1 - t) * step) % step;

    final gridLinePaint = Paint()
      ..color = AppColors.paperShadow.withValues(alpha: 0.65)
      ..strokeWidth = 1.0;

    for (double x = -step + driftX; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridLinePaint);
    }
    for (double y = -step + driftY; y < size.height + step; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridLinePaint);
    }

    // Sweeping horizontal maximalist scan band.
    final scanY = ((t * 1.25) % 1.0) * size.height;
    final scanPaint = Paint()
      ..color = AppColors.accentSky.withValues(alpha: 0.08)
      ..strokeWidth = AppSpacing.lg;
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scanPaint);

    // Accent diagonal rail.
    final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    final railPaint = Paint()
      ..color = AppColors.accentWarm.withValues(alpha: 0.10 + 0.10 * pulse)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(size.width * 0.12, 0),
      Offset(size.width * 0.88, size.height),
      railPaint,
    );

    // Single drawPoints pass for cyber intersection nodes.
    final nodePaint = Paint()
      ..color = AppColors.accentSky.withValues(alpha: 0.26)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[
      for (double x = driftX; x < size.width; x += step * 2)
        for (double y = driftY; y < size.height; y += step * 2) Offset(x, y),
    ];
    canvas.drawPoints(PointMode.points, points, nodePaint);
  }

  @override
  bool shouldRepaint(covariant _CyberMaxGridPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
