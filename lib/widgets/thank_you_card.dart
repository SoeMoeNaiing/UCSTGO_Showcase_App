import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import './sketch_animation.dart';

/// The success moment: a doodled character waves while a speech bubble
/// scribbles "Thank you!" — PROJECT_PROCESS.md §5.1.
///
/// Render-only (I24 chooses when to show it from `FeedbackSuccess`). The
/// whole visual is one semantic node so a screen reader hears the message
/// once. Rive replaces the hand-drawn character at I30; until then there
/// is no asset to fail to load on a kiosk.
class ThankYouCard extends StatelessWidget {
  const ThankYouCard({
    super.key,
    this.animationBackend = const NoOpSketchAnimationBackend(),
  });

  /// Injectable animation backend; the painter is always the fallback.
  final SketchAnimationBackend animationBackend;

  static const message = 'Thank you!';
  static const bubbleKey = Key('thank_you_bubble');
  static const characterKey = Key('thank_you_character');

  static const double _cardWidth = 240;
  static const double _cardHeight = 220;
  static const double _bubbleHeight = 88;
  static const double _characterSize = 120;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: message,
      child: ExcludeSemantics(
        child: SizedBox(
          width: _cardWidth,
          height: _cardHeight,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _bubbleHeight,
                child: CustomPaint(
                  key: bubbleKey,
                  painter: _SpeechBubblePainter(
                    ink: AppColors.inkPrimary,
                    paper: AppColors.paperWhite,
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTypography.headline,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: SizedBox.square(
                  dimension: _characterSize,
                  child: SketchAnimation(
                    painter: _CharacterPainter(
                      ink: AppColors.inkPrimary,
                      paper: AppColors.paperWhite,
                      blush: AppColors.accentBlush,
                      wave: AppColors.accentWarm,
                    ),
                    backend: animationBackend,
                    active: true,
                    fallbackKey: characterKey,
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, curve: Curves.easeOut)
            .scaleXY(
              begin: 0.9,
              end: 1,
              duration: 600.ms,
              curve: Curves.easeOutBack,
            )
            .slideY(begin: 0.08, end: 0, duration: 500.ms),
      ),
    );
  }
}

/// Wobbly speech bubble with a tail pointing down at the character.
class _SpeechBubblePainter extends CustomPainter {
  const _SpeechBubblePainter({required this.ink, required this.paper});

  final Color ink;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final bubble = _bubblePath(size);

    canvas.drawPath(
      bubble,
      Paint()..color = paper..style = PaintingStyle.fill,
    );

    // A faint offset second pass keeps the outline hand-drawn.
    canvas.save();
    canvas.translate(1.5, 1);
    canvas.drawPath(
      bubble,
      Paint()
        ..color = ink.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    canvas.drawPath(
      bubble,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _bubblePath(Size size) {
    final w = size.width;
    final bottom = size.height - 12; // leave room for the tail
    return Path()
      ..moveTo(20, 5)
      ..lineTo(w - 22, 7)
      ..quadraticBezierTo(w - 3, 8, w - 5, 24)
      ..lineTo(w - 7, bottom - 20)
      ..quadraticBezierTo(w - 9, bottom - 2, w - 26, bottom - 4)
      ..lineTo(w * 0.58, bottom - 4)
      ..lineTo(w * 0.52, bottom + 10)
      ..lineTo(w * 0.46, bottom - 4)
      ..lineTo(24, bottom - 4)
      ..quadraticBezierTo(4, bottom - 6, 5, bottom - 24)
      ..lineTo(3, 24)
      ..quadraticBezierTo(4, 6, 20, 5)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.paper != paper;
}

/// Simple waving stick character — ink strokes, paper fill, warm cheeks.
class _CharacterPainter extends CustomPainter {
  const _CharacterPainter({
    required this.ink,
    required this.paper,
    required this.blush,
    required this.wave,
  });

  final Color ink;
  final Color paper;
  final Color blush;
  final Color wave;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Head.
    final head = Offset(centerX, size.height * 0.27);
    final radius = size.width * 0.18;
    canvas.drawCircle(
      head,
      radius,
      Paint()..color = paper..style = PaintingStyle.fill,
    );
    canvas.drawCircle(head, radius, stroke);

    // Eyes + smile.
    final eyeY = head.dy - radius * 0.1;
    canvas.drawCircle(
      head.translate(-radius * 0.36, 0),
      2.2,
      Paint()..color = ink..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      head.translate(radius * 0.36, 0),
      2.2,
      Paint()..color = ink..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(head.dx - radius * 0.4, eyeY + radius * 0.35)
        ..quadraticBezierTo(
          head.dx,
          eyeY + radius * 0.85,
          head.dx + radius * 0.4,
          eyeY + radius * 0.35,
        ),
      stroke,
    );

    // Cheeks.
    final cheek = Paint()
      ..color = blush.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      head.translate(-radius * 0.72, radius * 0.35),
      3.4,
      cheek,
    );
    canvas.drawCircle(
      head.translate(radius * 0.72, radius * 0.35),
      3.4,
      cheek,
    );

    // Body, legs and the raised waving arm.
    final shoulder = Offset(centerX, size.height * 0.52);
    canvas.drawPath(
      Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(
          shoulder.dx + 3,
          size.height * 0.66,
          shoulder.dx,
          size.height * 0.76,
        ),
      stroke,
    );
    canvas.drawLine(
      shoulder,
      Offset(centerX - size.width * 0.22, size.height * 0.66),
      stroke,
    );
    canvas.drawLine(
      shoulder,
      Offset(centerX + size.width * 0.26, size.height * 0.38),
      stroke,
    );
    canvas.drawLine(
      Offset(centerX, size.height * 0.76),
      Offset(centerX - size.width * 0.14, size.height * 0.94),
      stroke,
    );
    canvas.drawLine(
      Offset(centerX, size.height * 0.76),
      Offset(centerX + size.width * 0.14, size.height * 0.94),
      stroke,
    );

    // Little motion strokes around the waving hand.
    final motion = Paint()
      ..color = wave
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final handX = centerX + size.width * 0.26;
    final handY = size.height * 0.38;
    for (final offset in const [-7.0, 0.0, 7.0]) {
      canvas.drawLine(
        Offset(handX + offset, handY - 6),
        Offset(handX + offset + 2, handY - 12),
        motion,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) =>
      oldDelegate.ink != ink ||
      oldDelegate.paper != paper ||
      oldDelegate.blush != blush ||
      oldDelegate.wave != wave;
}
