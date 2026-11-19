import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Heavy looping Showcase Maximalist background: drifting cyber grid,
/// sweeping scan beam, rotating orbital rings, and pulsing nodes.
class MaximalistBackdrop extends StatefulWidget {
  const MaximalistBackdrop({
    super.key,
    required this.child,
    this.overscan = 0.0,
  }) : assert(overscan >= 0 && overscan < 0.5);

  final Widget child;
  final double overscan;

  @override
  State<MaximalistBackdrop> createState() => _MaximalistBackdropState();
}

class _MaximalistBackdropState extends State<MaximalistBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.voidBlack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _MaximalistFieldPainter(phase: _controller),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final pad = widget.overscan * constraints.biggest.shortestSide;
              return SafeArea(
                minimum: EdgeInsets.all(pad),
                child: widget.child,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MaximalistFieldPainter extends CustomPainter {
  _MaximalistFieldPainter({required this.phase}) : super(repaint: phase);

  final Animation<double> phase;

  @override
  void paint(Canvas canvas, Size size) {
    final t = phase.value;
    const step = AppSpacing.xl * 1.5; // 48.0
    final driftX = (t * step) % step;
    final driftY = ((1 - t) * step) % step;

    final gridPaint = Paint()
      ..color = AppColors.gridLine.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;

    for (double x = -step + driftX; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = -step + driftY; y < size.height + step; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Sweeping horizontal scan beam.
    final scanY = ((t * 1.3) % 1.0) * size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 14, size.width, 28),
      Paint()..color = AppColors.electricCyan.withValues(alpha: 0.06),
    );

    // Rotating orbital rings in background.
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final radius = math.min(size.width, size.height) * 0.36;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * 2 * math.pi);

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      0,
      math.pi * 0.65,
      false,
      Paint()
        ..color = AppColors.electricCyan.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius * 0.78),
      math.pi * 0.8,
      math.pi * 0.55,
      false,
      Paint()
        ..color = AppColors.hyperCoral.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.restore();

    // Pulsing grid intersection nodes.
    final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    final nodes = <Offset>[
      for (double x = driftX; x < size.width; x += step * 2)
        for (double y = driftY; y < size.height; y += step * 2) Offset(x, y),
    ];
    canvas.drawPoints(
      PointMode.points,
      nodes,
      Paint()
        ..color = AppColors.acidLime.withValues(alpha: 0.16 + 0.18 * pulse)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MaximalistFieldPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
