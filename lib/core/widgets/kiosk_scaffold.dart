import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Root scaffold for every kiosk screen — PROJECT_PROCESS.md §4.1, §5.1, §5.5.
///
/// Owns the shared visual surface so feature screens never re-implement it:
///
/// * warm paper background from [AppColors.paperBackground],
/// * faint dot-grid "paper texture" (single `drawPoints` call — cheap on
///   low-end TV GPUs, §2.3.3),
/// * TV overscan protection: [overscan] is a fraction of the shortest side
///   (Phase 6 locks it to 5%, §5.5; phone default stays edge-to-edge),
/// * optional decorative [background] layer for the attract mode
///   (Iteration 36) — painted behind content and always input-transparent.
///
/// The scaffold is deliberately *dumb*: no state, no providers, no motion.
class KioskScaffold extends StatelessWidget {
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
  /// 0.0 on phone; 0.05 for TV (Phase 6, §5.5).
  final double overscan;

  /// Toggles the paper dot-grid texture (useful for golden/clean captures).
  final bool showGrid;

  /// Stable key for the texture layer so tests can prove it paints.
  static const gridKey = Key('kiosk_dot_grid');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (showGrid)
            const IgnorePointer(
              child: CustomPaint(
                key: gridKey,
                painter: _DotGridPainter(),
              ),
            ),
          if (background != null)
            IgnorePointer(child: background!),
          LayoutBuilder(
            builder: (context, constraints) {
              final inset = overscan * constraints.biggest.shortestSide;
              return SafeArea(
                minimum: EdgeInsets.all(inset),
                child: child,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Faint dot-grid "paper texture" (§5.1).
///
/// One `drawPoints` call instead of ~14k `drawCircle` calls on a 4K TV —
/// the difference between a texture and a jank source (§2.3.3).
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  static const double _dotOpacity = 0.06;
  static const double _dotRadius = 1.2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.inkSecondary.withValues(alpha: _dotOpacity)
      ..strokeWidth = _dotRadius * 2
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[
      for (var x = AppSpacing.xl / 2; x < size.width; x += AppSpacing.xl)
        for (var y = AppSpacing.xl / 2; y < size.height; y += AppSpacing.xl)
          Offset(x, y),
    ];

    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}
