import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import './sketch_animation.dart';

/// Cyber-Brutalist success badge + animated character preserving
/// [ThankYouCard.message], [ThankYouCard.bubbleKey], and [ThankYouCard.characterKey].
class ThankYouCard extends StatefulWidget {
  const ThankYouCard({
    super.key,
    this.animationBackend = const NoOpSketchAnimationBackend(),
  });

  final SketchAnimationBackend animationBackend;

  static const message = 'Thank you!';
  static const bubbleKey = Key('thank_you_bubble');
  static const characterKey = Key('thank_you_character');

  static const double _cardWidth = 260;
  static const double _cardHeight = 230;
  static const double _bubbleHeight = 90;
  static const double _characterSize = 120;

  @override
  State<ThankYouCard> createState() => _ThankYouCardState();
}

class _ThankYouCardState extends State<ThankYouCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  bool get _shouldAnimateWave =>
      widget.animationBackend is! NoOpSketchAnimationBackend;

  @override
  void initState() {
    super.initState();
    _syncWaveLoop();
  }

  @override
  void didUpdateWidget(covariant ThankYouCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationBackend.runtimeType !=
        widget.animationBackend.runtimeType) {
      _syncWaveLoop();
    }
  }

  void _syncWaveLoop() {
    if (_shouldAnimateWave) {
      if (!_waveController.isAnimating) {
        _waveController.repeat(reverse: true);
      }
    } else {
      _waveController.stop();
      _waveController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final characterPainter = _CyberCharacterPainter(
      ink: AppColors.inkPrimary,
      paper: AppColors.paperWhite,
      blush: AppColors.accentBlush,
      wave: AppColors.accentWarm,
      waveProgress: _shouldAnimateWave ? _waveController : null,
    );

    return Semantics(
      container: true,
      label: ThankYouCard.message,
      child: ExcludeSemantics(
        child:
            SizedBox(
                  width: ThankYouCard._cardWidth,
                  height: ThankYouCard._cardHeight,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: ThankYouCard._bubbleHeight,
                        child:
                            CustomPaint(
                                  key: ThankYouCard.bubbleKey,
                                  painter: _CyberBubblePainter(
                                    ink: AppColors.accentSky,
                                    paper: AppColors.paperWhite,
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.sm,
                                      ),
                                      child: Text(
                                        ThankYouCard.message,
                                        textAlign: TextAlign.center,
                                        style: AppTypography.headline.copyWith(
                                          color: AppColors.inkPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 100.ms, duration: 300.ms)
                                .scaleXY(
                                  begin: 0.88,
                                  end: 1.0,
                                  delay: 100.ms,
                                  duration: 360.ms,
                                  curve: Curves.easeOutBack,
                                ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: SizedBox.square(
                          dimension: ThankYouCard._characterSize,
                          child: SketchAnimation(
                            painter: characterPainter,
                            backend: widget.animationBackend,
                            active: true,
                            fallbackKey: ThankYouCard.characterKey,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                .scaleXY(
                  begin: 0.92,
                  end: 1.0,
                  duration: 420.ms,
                  curve: Curves.easeOutBack,
                ),
      ),
    );
  }
}

class _CyberBubblePainter extends CustomPainter {
  const _CyberBubblePainter({required this.ink, required this.paper});

  final Color ink;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 8, size.height - 16),
      const Radius.circular(AppSpacing.xs),
    );

    canvas.drawRRect(
      rect.shift(const Offset(4, 4)),
      Paint()..color = AppColors.accentWarm,
    );
    canvas.drawRRect(rect, Paint()..color = paper);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final tail = Path()
      ..moveTo(size.width * 0.44, rect.bottom)
      ..lineTo(size.width * 0.50, size.height - 2)
      ..lineTo(size.width * 0.56, rect.bottom)
      ..close();
    canvas.drawPath(tail, Paint()..color = paper);
    canvas.drawPath(
      tail,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant _CyberBubblePainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.paper != paper;
}

class _CyberCharacterPainter extends CustomPainter {
  const _CyberCharacterPainter({
    required this.ink,
    required this.paper,
    required this.blush,
    required this.wave,
    this.waveProgress,
  }) : super(repaint: waveProgress);

  final Color ink;
  final Color paper;
  final Color blush;
  final Color wave;
  final Animation<double>? waveProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final t = waveProgress?.value ?? 0.5;
    final swing = (t - 0.5) * 2;

    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.square;

    final head = Offset(centerX, size.height * 0.27);
    final radius = size.width * 0.18;

    canvas.drawCircle(
      head,
      radius,
      Paint()
        ..color = paper
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(head, radius, stroke..color = AppColors.accentSky);

    canvas.drawCircle(
      head.translate(-radius * 0.35, -radius * 0.05),
      2.4,
      Paint()..color = ink,
    );
    canvas.drawCircle(
      head.translate(radius * 0.35, -radius * 0.05),
      2.4,
      Paint()..color = ink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(head.dx - radius * 0.4, head.dy + radius * 0.25)
        ..quadraticBezierTo(
          head.dx,
          head.dy + radius * 0.75,
          head.dx + radius * 0.4,
          head.dy + radius * 0.25,
        ),
      stroke..color = ink,
    );

    final cheek = Paint()..color = blush.withValues(alpha: 0.6);
    canvas.drawCircle(
      head.translate(-radius * 0.72, radius * 0.32),
      3.4,
      cheek,
    );
    canvas.drawCircle(head.translate(radius * 0.72, radius * 0.32), 3.4, cheek);

    final shoulder = Offset(centerX, size.height * 0.52);
    canvas.drawLine(shoulder, Offset(centerX, size.height * 0.76), stroke);
    canvas.drawLine(
      shoulder,
      Offset(centerX - size.width * 0.22, size.height * 0.66),
      stroke,
    );

    final armAngle = -0.65 + swing * 0.38;
    const armLength = 34.0;
    final handOffset = Offset(
      shoulder.dx + math.cos(armAngle) * armLength,
      shoulder.dy + math.sin(armAngle) * armLength,
    );
    canvas.drawLine(shoulder, handOffset, stroke..color = wave);

    canvas.drawLine(
      Offset(centerX, size.height * 0.76),
      Offset(centerX - size.width * 0.14, size.height * 0.94),
      stroke..color = ink,
    );
    canvas.drawLine(
      Offset(centerX, size.height * 0.76),
      Offset(centerX + size.width * 0.14, size.height * 0.94),
      stroke..color = ink,
    );

    final motion = Paint()
      ..color = AppColors.idleGlow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    for (final offset in const [-7.0, 0.0, 7.0]) {
      final tickShift = swing * 2.5;
      canvas.drawLine(
        Offset(handOffset.dx + offset + tickShift, handOffset.dy - 6),
        Offset(handOffset.dx + offset + 2 + tickShift, handOffset.dy - 12),
        motion,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CyberCharacterPainter oldDelegate) =>
      oldDelegate.ink != ink ||
      oldDelegate.paper != paper ||
      oldDelegate.blush != blush ||
      oldDelegate.wave != wave ||
      oldDelegate.waveProgress != waveProgress;
}
