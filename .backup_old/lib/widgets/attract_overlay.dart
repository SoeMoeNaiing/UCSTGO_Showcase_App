import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Cyber-Brutalist Maximalist attract loop: after [idleDuration] without input,
/// a kinetic welcome overlay with looping geometric/cyber motion covers the
/// screen; any touch or key dismisses it and resets the timer.
///
/// Preserves [AttractOverlay.overlayKey] and avoids autofocus so screen
/// focus targets remain intact.
class AttractOverlay extends StatefulWidget {
  const AttractOverlay({
    super.key,
    required this.child,
    this.idleDuration = const Duration(seconds: 20),
  });

  final Widget child;

  /// Tunable; defaults to the 20s attract loop.
  final Duration idleDuration;

  static const overlayKey = Key('attract_overlay');

  @override
  State<AttractOverlay> createState() => _AttractOverlayState();
}

class _AttractOverlayState extends State<AttractOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _idle = false;

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
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
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: _MaximalistOrbitPainter(
                                progress: _loop,
                                warm: AppColors.accentWarm,
                                sky: AppColors.accentSky,
                                glow: AppColors.idleGlow,
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.lg,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paperWhite,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.xs,
                                ),
                                border: Border.all(
                                  color: AppColors.accentWarm,
                                  width: 2.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.accentSky,
                                    offset: Offset(6, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'WELCOME TO UCSTGO',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.display.copyWith(
                                      color: AppColors.inkPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  SizedBox(
                                    width: 260,
                                    height: 18,
                                    child: AnimatedBuilder(
                                      animation: _loop,
                                      builder: (context, _) => CustomPaint(
                                        painter: _PencilUnderlinePainter(
                                          progress: _loop.value,
                                          color: AppColors.accentWarm,
                                          accent: AppColors.accentSky,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'TOUCH OR PRESS ANY KEY TO BEGIN',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.accentSky,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

/// Looping maximalist geometric rings & telemetry ticks in attract mode.
class _MaximalistOrbitPainter extends CustomPainter {
  _MaximalistOrbitPainter({
    required this.progress,
    required this.warm,
    required this.sky,
    required this.glow,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color warm;
  final Color sky;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value * 2 * math.pi;
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) * 0.34;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * 0.25);

    final outerRect = Rect.fromCircle(center: Offset.zero, radius: baseRadius);
    canvas.drawArc(
      outerRect,
      0,
      math.pi * 0.7,
      false,
      Paint()
        ..color = sky.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawArc(
      outerRect,
      math.pi,
      math.pi * 0.65,
      false,
      Paint()
        ..color = warm.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final markerAngle = t;
    final markerPos = Offset(
      math.cos(markerAngle) * baseRadius,
      math.sin(markerAngle) * baseRadius,
    );
    canvas.drawCircle(
      markerPos,
      6,
      Paint()..color = glow.withValues(alpha: 0.8),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MaximalistOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.warm != warm ||
      oldDelegate.sky != sky ||
      oldDelegate.glow != glow;
}

/// A sharp kinetic bar that sweeps across with a secondary cyan trail.
class _PencilUnderlinePainter extends CustomPainter {
  const _PencilUnderlinePainter({
    required this.progress,
    required this.color,
    required this.accent,
  });

  final double progress;
  final Color color;
  final Color accent;

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
      final y = size.height / 2 + (step.isEven ? 2.0 : -2.0);
      if (step == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawLine(
      Offset(0, size.height / 2 + 4),
      Offset(
        size.width * ((progress * 0.75).clamp(0.0, 1.0)),
        size.height / 2 + 4,
      ),
      Paint()
        ..color = accent.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.square,
    );
  }

  @override
  bool shouldRepaint(covariant _PencilUnderlinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.accent != accent;
}
