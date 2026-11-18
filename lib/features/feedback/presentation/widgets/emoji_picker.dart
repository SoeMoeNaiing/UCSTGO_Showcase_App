import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/emoji_choice.dart';

/// The three hand-drawn sentiment faces — PROJECT_PROCESS.md §5.1.
///
/// **Render-only (Iteration 18).** Tap, D-pad focus, double-tap throttling
/// and the selection animation arrive in Iteration 19; the geometry and
/// semantics are already final so that iteration only adds behaviour.
///
/// Everything is sourced from tokens: the outline from
/// [AppColors.inkPrimary], each face's marker wash from the accent palette,
/// spacing from [AppSpacing] and type from [AppTypography]. No raw hex —
/// §2.1.4, guarded by `test/core/theme/design_tokens_test.dart`.
class EmojiPicker extends StatelessWidget {
  const EmojiPicker({super.key, this.maxFaceSize = 180})
      : assert(maxFaceSize > 0, 'maxFaceSize must be positive');

  /// Upper bound for one face. Phones scale down from here; a 4K TV can
  /// raise it without touching the painter.
  final double maxFaceSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Each face is a third of the row minus breathing room. The cap
        // keeps 10-foot sizing from turning into a giant on wide screens.
        final raw = (constraints.maxWidth - AppSpacing.lg * 2) / 3;
        final faceSize =
            raw.isFinite ? raw.clamp(0.0, maxFaceSize).toDouble() : maxFaceSize;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final choice in EmojiChoice.values)
              EmojiFace(choice: choice, size: faceSize),
          ],
        );
      },
    );
  }
}

/// One sketch-outlined sentiment face plus its visible label.
///
/// The whole unit is a single semantic node ("Satisfied", "Neutral",
/// "Dissatisfied"); the visible text is excluded so a screen reader never
/// reads the same choice twice.
class EmojiFace extends StatelessWidget {
  const EmojiFace({
    super.key,
    required this.choice,
    required this.size,
  }) : assert(size > 0, 'size must be positive');

  /// Sentiment rendered by this face.
  final EmojiChoice choice;

  /// Width and height of the drawn face (the label sits underneath).
  final double size;

  /// Stable canvas key so tests can measure the square face itself.
  static Key canvasKeyFor(EmojiChoice choice) =>
      ValueKey('emoji-face-canvas-${choice.wireValue}');

  /// Spoken label for assistive tech — the domain vocabulary, not the
  /// friendlier visible copy.
  static String semanticLabelFor(EmojiChoice choice) => switch (choice) {
        EmojiChoice.satisfied => 'Satisfied',
        EmojiChoice.neutral => 'Neutral',
        EmojiChoice.dissatisfied => 'Dissatisfied',
      };

  /// Short visible copy, readable at 10 feet.
  static String visibleLabelFor(EmojiChoice choice) => switch (choice) {
        EmojiChoice.satisfied => 'Loved it',
        EmojiChoice.neutral => 'Okay',
        EmojiChoice.dissatisfied => 'Not great',
      };

  Color get _accent => switch (choice) {
        EmojiChoice.satisfied => AppColors.accentSage,
        EmojiChoice.neutral => AppColors.accentSky,
        EmojiChoice.dissatisfied => AppColors.accentBlush,
      };

  /// A few degrees of asymmetry make the row feel hand-placed, not stamped.
  double get _tilt => switch (choice) {
        EmojiChoice.satisfied => -0.025,
        EmojiChoice.neutral => 0.015,
        EmojiChoice.dissatisfied => -0.01,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabelFor(choice),
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: size,
                child: Transform.rotate(
                  angle: _tilt,
                  child: CustomPaint(
                    key: canvasKeyFor(choice),
                    painter: _EmojiFacePainter(
                      choice: choice,
                      ink: AppColors.inkPrimary,
                      accent: _accent,
                      blush: AppColors.accentBlush,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                visibleLabelFor(choice),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints one face as three or four wobbly ink strokes on paper.
///
/// Deliberately cheap: a handful of paths per face, one `CustomPaint` each,
/// no shaders or save layers — safe for a low-end TV GPU (§2.3.3).
class _EmojiFacePainter extends CustomPainter {
  const _EmojiFacePainter({
    required this.choice,
    required this.ink,
    required this.accent,
    required this.blush,
  });

  final EmojiChoice choice;
  final Color ink;
  final Color accent;
  final Color blush;

  static const double _washOpacity = 0.16;
  static const double _blushOpacity = 0.5;

  /// Deterministic wobble phase per face so repaints never shimmer.
  int get _seed => switch (choice) {
        EmojiChoice.satisfied => 3,
        EmojiChoice.neutral => 11,
        EmojiChoice.dissatisfied => 19,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);

    // A soft accent swipe behind the face, like a marker highlight.
    final wash = Paint()
      ..color = accent.withValues(alpha: _washOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      _blob(
        center.translate(side * 0.01, side * 0.015),
        side * 0.46,
        seed: _seed + 5,
      ),
      wash,
    );

    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.018
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // A faint second pass, offset by a hair — the "drawn twice" pencil look.
    final ghost = Paint()
      ..color = ink.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.012
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      _blob(
        center.translate(-side * 0.007, side * 0.006),
        side * 0.405,
        seed: _seed + 1,
      ),
      ghost,
    );

    canvas.drawPath(_blob(center, side * 0.41, seed: _seed), stroke);
    _paintFeatures(canvas, side, center, stroke);
  }

  void _paintFeatures(Canvas canvas, double side, Offset center, Paint stroke) {
    final eyeY = center.dy - side * 0.07;
    final leftEye = Offset(center.dx - side * 0.16, eyeY);
    final rightEye = Offset(center.dx + side * 0.16, eyeY);

    if (choice == EmojiChoice.satisfied) {
      _drawClosedEye(canvas, leftEye, side, stroke);
      _drawClosedEye(canvas, rightEye, side, stroke);
      _drawCheeks(canvas, center, side);
    } else {
      _drawDotEye(canvas, leftEye, side);
      _drawDotEye(canvas, rightEye, side);
    }

    _drawMouth(canvas, center, side, stroke);
  }

  /// A happy "^" eye: an upward-bowed arc.
  void _drawClosedEye(Canvas canvas, Offset eye, double side, Paint stroke) {
    final width = side * 0.13;
    final path = Path()
      ..moveTo(eye.dx - width / 2, eye.dy + width * 0.12)
      ..quadraticBezierTo(
        eye.dx,
        eye.dy - width * 0.45,
        eye.dx + width / 2,
        eye.dy + width * 0.12,
      );
    canvas.drawPath(path, stroke);
  }

  void _drawDotEye(Canvas canvas, Offset eye, double side) {
    final dot = Paint()
      ..color = ink
      ..style = PaintingStyle.fill;
    canvas.drawCircle(eye, side * 0.027, dot);
  }

  void _drawCheeks(Canvas canvas, Offset center, double side) {
    final cheek = Paint()
      ..color = blush.withValues(alpha: _blushOpacity)
      ..style = PaintingStyle.fill;
    final y = center.dy + side * 0.1;
    canvas.drawCircle(
      Offset(center.dx - side * 0.27, y),
      side * 0.05,
      cheek,
    );
    canvas.drawCircle(
      Offset(center.dx + side * 0.27, y),
      side * 0.05,
      cheek,
    );
  }

  void _drawMouth(Canvas canvas, Offset center, double side, Paint stroke) {
    final halfWidth = side * 0.15;
    final mouthY = center.dy + side * 0.12;
    final path = Path();

    switch (choice) {
      case EmojiChoice.satisfied:
        // A big "U" smile.
        path
          ..moveTo(center.dx - halfWidth, mouthY)
          ..quadraticBezierTo(
            center.dx,
            mouthY + side * 0.16,
            center.dx + halfWidth,
            mouthY,
          );
      case EmojiChoice.neutral:
        // A small wavy line — not a frown, not a smile.
        path
          ..moveTo(center.dx - halfWidth, mouthY + side * 0.02)
          ..quadraticBezierTo(
            center.dx - halfWidth / 2,
            mouthY - side * 0.01,
            center.dx,
            mouthY + side * 0.02,
          )
          ..quadraticBezierTo(
            center.dx + halfWidth / 2,
            mouthY + side * 0.05,
            center.dx + halfWidth,
            mouthY + side * 0.02,
          );
      case EmojiChoice.dissatisfied:
        // An inverted "U" frown: corners down, centre up.
        path
          ..moveTo(center.dx - halfWidth, mouthY + side * 0.07)
          ..quadraticBezierTo(
            center.dx,
            mouthY - side * 0.1,
            center.dx + halfWidth,
            mouthY + side * 0.07,
          );
    }

    canvas.drawPath(path, stroke);
  }

  /// A closed but slightly irregular circle, sampled with two low-frequency
  /// sine waves — hand-drawn without randomness.
  Path _blob(Offset center, double radius, {required int seed}) {
    const steps = 48;
    final path = Path();

    for (var i = 0; i <= steps; i++) {
      final angle = 2 * math.pi * i / steps;
      final wobble = 1 +
          0.018 * math.sin(3 * angle + seed) +
          0.011 * math.sin(5 * angle - seed * 1.7);
      final point = center +
          Offset(
            math.cos(angle) * radius * wobble,
            math.sin(angle) * radius * wobble,
          );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    return path..close();
  }

  @override
  bool shouldRepaint(covariant _EmojiFacePainter oldDelegate) =>
      oldDelegate.choice != choice ||
      oldDelegate.ink != ink ||
      oldDelegate.accent != accent ||
      oldDelegate.blush != blush;
}
