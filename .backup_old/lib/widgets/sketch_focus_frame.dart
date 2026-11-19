import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Draws the sketch focus frame as two jittered pencil passes that "write"
/// themselves in as [progress] runs from 0 to 1 (§5.1, §2.3.2).
///
/// Deliberately in-house: `rough_notation`'s autoplay timer calls
/// `AnimationController.forward()` after dispose when focus moves quickly,
/// which is a real race on a D-pad. This painter owns no timers — its owner
/// supplies the [Animation] (normally an `AnimationController`).
///
/// Shared by the emoji faces (I19) and the rating prompt (I23) so every
/// focusable kiosk control has the same unmistakable focus affordance.
class SketchFocusFramePainter extends CustomPainter {
  SketchFocusFramePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Two passes, different jitter — a box drawn twice by hand.
    for (final seed in const [7, 23]) {
      final path = _jitteredRect(size, seed);
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
      }
    }
  }

  Path _jitteredRect(Size size, int seed) {
    final random = math.Random(seed);
    Offset corner(double x, double y) => Offset(
      x + random.nextDouble() * 5 - 2.5,
      y + random.nextDouble() * 5 - 2.5,
    );

    final topLeft = corner(0, 0);
    final topRight = corner(size.width, 0);
    final bottomRight = corner(size.width, size.height);
    final bottomLeft = corner(0, size.height);

    return Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
  }

  @override
  bool shouldRepaint(covariant SketchFocusFramePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
