import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import './sketch_animation.dart';
import './sketch_focus_frame.dart';
import '../models/emoji_choice.dart';

/// The three hand-drawn sentiment faces — PROJECT_PROCESS.md §5.1.
///
/// Interactive since Iteration 19: every face is a focusable button (tap,
/// Enter/D-pad, arrow traversal) with a hand-drawn focus frame and a single
/// 2-second selection window shared by all three faces (§7 client throttle).
/// Geometry and colors still come from tokens only — §2.1.4.
class EmojiPicker extends StatefulWidget {
  const EmojiPicker({
    super.key,
    required this.onSelected,
    this.maxFaceSize = 180,
    this.throttle = const Duration(seconds: 2),
    this.autofocusFirst = false,
    this.faceAnimationBackend,
  })  : assert(maxFaceSize > 0, 'maxFaceSize must be positive'),
        assert(throttle > Duration.zero, 'throttle must be positive');

  /// Fired once per accepted activation. Activations inside [throttle]
  /// never reach this callback — the submit path stays single-shot.
  final ValueChanged<EmojiChoice> onSelected;

  /// Upper bound for one face. Phones scale down from here; a 4K TV can
  /// raise it without touching the painter.
  final double maxFaceSize;

  /// §7 client throttle: a second activation inside this window is dropped.
  final Duration throttle;

  /// Requests focus on the first (happy) face after the first frame.
  /// Used by the TV pass; I24 decides the phone default.
  final bool autofocusFirst;

  /// Optional animated backend for the faces (I30 Rive seam). When null the
  /// proven `CustomPainter` path is used unchanged.
  final SketchAnimationBackend? faceAnimationBackend;

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> {
  Timer? _throttleTimer;

  bool get _isThrottled => _throttleTimer?.isActive ?? false;

  void _select(EmojiChoice choice) {
    if (_isThrottled) {
      return;
    }
    // The inactive timer itself is the release signal — no wall clock.
    _throttleTimer = Timer(widget.throttle, _endThrottle);
    widget.onSelected(choice);
  }

  void _endThrottle() {
    // Intentionally empty: timer inactivity is the release signal.
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Each face is a third of the row minus breathing room. The cap
        // keeps 10-foot sizing from turning into a giant on wide screens.
        final raw = (constraints.maxWidth - AppSpacing.lg * 2) / 3;
        final faceSize = raw.isFinite
            ? raw.clamp(0.0, widget.maxFaceSize).toDouble()
            : widget.maxFaceSize;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final choice in EmojiChoice.values)
              EmojiFace(
                choice: choice,
                size: faceSize,
                autofocus: widget.autofocusFirst &&
                    choice == EmojiChoice.values.first,
                animationBackend: widget.faceAnimationBackend,
                onActivate: () => _select(choice),
              ),
          ],
        );
      },
    );
  }
}

/// One sketch-outlined sentiment face plus its visible label.
///
/// A focusable button: tap, Enter/Space/Select or D-pad activate it. Focus
/// draws an animated rough frame and pops the face; arrow keys move through
/// Flutter's default directional traversal. The whole unit is a single
/// semantic node ("Satisfied", …) with a tap action.
class EmojiFace extends StatefulWidget {
  const EmojiFace({
    super.key,
    required this.choice,
    required this.size,
    required this.onActivate,
    this.autofocus = false,
    this.animationBackend,
  }) : assert(size > 0, 'size must be positive');

  /// Sentiment rendered by this face.
  final EmojiChoice choice;

  /// Width and height of the drawn face (the label sits underneath).
  final double size;

  /// Called for every accepted tap or keyboard activation.
  final VoidCallback onActivate;

  /// Requests focus after the first frame (first face on TV).
  final bool autofocus;

  /// Optional animated backend (I30 Rive seam). Null keeps the original
  /// painter path so all existing focus/keyboard tests are unaffected.
  final SketchAnimationBackend? animationBackend;

  /// Stable canvas key so tests can measure the square face itself.
  static Key canvasKeyFor(EmojiChoice choice) =>
      ValueKey('emoji-face-canvas-${choice.wireValue}');

  /// Stable key for the rough focus frame so tests can assert visibility.
  static Key focusBoxKeyFor(EmojiChoice choice) =>
      ValueKey('emoji-focus-box-${choice.wireValue}');

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

  @override
  State<EmojiFace> createState() => _EmojiFaceState();
}

class _EmojiFaceState extends State<EmojiFace>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode =
      FocusNode(debugLabel: 'emoji-${widget.choice.wireValue}');
  late final AnimationController _frameController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  bool _focused = false;

  Color get _accent => switch (widget.choice) {
        EmojiChoice.satisfied => AppColors.accentSage,
        EmojiChoice.neutral => AppColors.accentSky,
        EmojiChoice.dissatisfied => AppColors.accentBlush,
      };

  /// A few degrees of asymmetry make the row feel hand-placed, not stamped.
  double get _tilt => switch (widget.choice) {
        EmojiChoice.satisfied => -0.025,
        EmojiChoice.neutral => 0.015,
        EmojiChoice.dissatisfied => -0.01,
      };

  @override
  void dispose() {
    _frameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _activate() {
    // Touch must leave the same visible focus state as D-pad navigation.
    _focusNode.requestFocus();
    widget.onActivate();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return Semantics(
      container: true,
      button: true,
      label: EmojiFace.semanticLabelFor(widget.choice),
      onTap: _activate,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          onFocusChange: (hasFocus) {
            if (!mounted || hasFocus == _focused) {
              return;
            }
            if (hasFocus) {
              _frameController.forward(from: 0);
            } else {
              _frameController.value = 0;
            }
            setState(() => _focused = hasFocus);
          },
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _activate();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _activate,
            child: SizedBox(
              width: size,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: size,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: AnimatedScale(
                            scale: _focused ? 1.06 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutBack,
                            child: Transform.rotate(
                              angle: _tilt,
                              child: widget.animationBackend == null
                                  ? CustomPaint(
                                      key: EmojiFace.canvasKeyFor(
                                        widget.choice,
                                      ),
                                      painter: _EmojiFacePainter(
                                        choice: widget.choice,
                                        ink: AppColors.inkPrimary,
                                        accent: _accent,
                                        blush: AppColors.accentBlush,
                                      ),
                                    )
                                  : SketchAnimation(
                                      painter: _EmojiFacePainter(
                                        choice: widget.choice,
                                        ink: AppColors.inkPrimary,
                                        accent: _accent,
                                        blush: AppColors.accentBlush,
                                      ),
                                      backend: widget.animationBackend!,
                                      active: _focused,
                                      fallbackKey:
                                          EmojiFace.canvasKeyFor(widget.choice),
                                    ),
                            ),
                          ),
                        ),
                        if (_focused)
                          Positioned(
                            left: -size * 0.06,
                            top: -size * 0.06,
                            width: size * 1.12,
                            height: size * 1.12,
                            child: IgnorePointer(
                              child: CustomPaint(
                                key: EmojiFace.focusBoxKeyFor(widget.choice),
                                painter: SketchFocusFramePainter(
                                  progress: _frameController,
                                  color: AppColors.accentWarm,
                                  strokeWidth: math.max(2.0, size * 0.016),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    EmojiFace.visibleLabelFor(widget.choice),
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
