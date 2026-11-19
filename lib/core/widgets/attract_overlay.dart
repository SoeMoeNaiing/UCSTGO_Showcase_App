import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Kiosk attract mode: after [idleDuration] without input, a pencil-drawn
/// welcome loop covers the screen; any touch or key dismisses it and resets
/// the timer (§5.1, §13).
///
/// The wrapper deliberately does **not** autofocus — key events bubble up
/// from whatever the screen focused (first face, first star), so initial
/// focus targets stay intact. The visual is `IgnorePointer`; input is caught
/// by the wrapper's [Listener] and [Focus] instead.
class AttractOverlay extends StatefulWidget {
  const AttractOverlay({
    super.key,
    required this.child,
    this.idleDuration = const Duration(seconds: 20),
  });

  final Widget child;

  /// Tunable per §13; defaults to the 20s attract loop.
  final Duration idleDuration;

  static const overlayKey = Key('attract_overlay');

  @override
  State<AttractOverlay> createState() => _AttractOverlayState();
}

class _AttractOverlayState extends State<AttractOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _idle = false;

  /// Loops the "pencil drawing" underline; no asset, no network.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loop.dispose();
    super.dispose();
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer(widget.idleDuration, _goIdle);
  }

  void _wake() {
    _arm();
    if (_idle && mounted) {
      setState(() => _idle = false);
    }
  }

  void _goIdle() {
    if (mounted) {
      setState(() => _idle = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _wake(),
      child: Focus(
        onKeyEvent: (node, event) {
          _wake();
          // Let the screen keep handling its own keys.
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            widget.child,
            if (_idle)
              Positioned.fill(
                child: IgnorePointer(
                  child: KeyedSubtree(
                    key: AttractOverlay.overlayKey,
                    child: ColoredBox(
                      color: AppColors.paperBackground.withValues(alpha: 0.96),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Welcome to UCSTGO',
                              textAlign: TextAlign.center,
                              style: AppTypography.display.copyWith(
                                color: AppColors.inkPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: 240,
                              height: 16,
                              child: AnimatedBuilder(
                                animation: _loop,
                                builder: (context, _) => CustomPaint(
                                  painter: _PencilUnderlinePainter(
                                    progress: _loop.value,
                                    color: AppColors.accentWarm,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Touch or press any key to begin',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A wobbly line that draws itself from left to right, looping forever.
class _PencilUnderlinePainter extends CustomPainter {
  const _PencilUnderlinePainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }

    final end = size.width * progress;
    final path = Path();
    const steps = 24;
    for (var step = 0; step <= steps; step++) {
      final x = end * step / steps;
      final y = size.height / 2 + (step.isEven ? 1.5 : -1.5);
      if (step == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PencilUnderlinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
