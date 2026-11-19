import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/emoji_choice.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import './sketch_animation.dart';
import './sketch_focus_frame.dart';

/// Cyber-Brutalist Maximalist sentiment selectors preserving all keys,
/// semantics, throttle behavior, and D-pad/keyboard focus traversal.
class EmojiPicker extends StatefulWidget {
  const EmojiPicker({
    super.key,
    required this.onSelected,
    this.maxFaceSize = 180,
    this.throttle = const Duration(seconds: 2),
    this.autofocusFirst = false,
    this.faceAnimationBackend,
  }) : assert(maxFaceSize > 0, 'maxFaceSize must be positive'),
       assert(throttle > Duration.zero, 'throttle must be positive');

  final ValueChanged<EmojiChoice> onSelected;
  final double maxFaceSize;
  final Duration throttle;
  final bool autofocusFirst;
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
    _throttleTimer = Timer(widget.throttle, _endThrottle);
    widget.onSelected(choice);
  }

  void _endThrottle() {}

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
                autofocus:
                    widget.autofocusFirst && choice == EmojiChoice.values.first,
                animationBackend: widget.faceAnimationBackend,
                onActivate: () => _select(choice),
              ),
          ],
        );
      },
    );
  }
}

/// One Cyber-Brutalist sentiment face tile + label.
class EmojiFace extends StatefulWidget {
  const EmojiFace({
    super.key,
    required this.choice,
    required this.size,
    required this.onActivate,
    this.autofocus = false,
    this.animationBackend,
  }) : assert(size > 0, 'size must be positive');

  final EmojiChoice choice;
  final double size;
  final VoidCallback onActivate;
  final bool autofocus;
  final SketchAnimationBackend? animationBackend;

  static Key canvasKeyFor(EmojiChoice choice) =>
      ValueKey('emoji-face-canvas-${choice.wireValue}');

  static Key focusBoxKeyFor(EmojiChoice choice) =>
      ValueKey('emoji-focus-box-${choice.wireValue}');

  static String semanticLabelFor(EmojiChoice choice) => switch (choice) {
    EmojiChoice.satisfied => 'Satisfied',
    EmojiChoice.neutral => 'Neutral',
    EmojiChoice.dissatisfied => 'Dissatisfied',
  };

  static String visibleLabelFor(EmojiChoice choice) => switch (choice) {
    EmojiChoice.satisfied => 'LOVED IT',
    EmojiChoice.neutral => 'OKAY',
    EmojiChoice.dissatisfied => 'NOT GREAT',
  };

  @override
  State<EmojiFace> createState() => _EmojiFaceState();
}

class _EmojiFaceState extends State<EmojiFace> with TickerProviderStateMixin {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'emoji-${widget.choice.wireValue}',
  );
  late final AnimationController _frameController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);
  bool _focused = false;

  Color get _accent => switch (widget.choice) {
    EmojiChoice.satisfied => AppColors.accentSage,
    EmojiChoice.neutral => AppColors.accentSky,
    EmojiChoice.dissatisfied => AppColors.accentBlush,
  };

  double get _tilt => switch (widget.choice) {
    EmojiChoice.satisfied => -0.02,
    EmojiChoice.neutral => 0.012,
    EmojiChoice.dissatisfied => -0.012,
  };

  @override
  void dispose() {
    _frameController.dispose();
    _pulseController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _activate() {
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
                            scale: _focused ? 1.07 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutBack,
                            child: Transform.rotate(
                              angle: _tilt,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.paperWhite,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.xs,
                                  ),
                                  border: Border.all(
                                    color: _focused
                                        ? _accent
                                        : AppColors.paperShadow,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _focused
                                          ? _accent
                                          : AppColors.paperShadow,
                                      offset: const Offset(4, 4),
                                    ),
                                  ],
                                ),
                                child: widget.animationBackend == null
                                    ? CustomPaint(
                                        key: EmojiFace.canvasKeyFor(
                                          widget.choice,
                                        ),
                                        painter: _CyberEmojiFacePainter(
                                          choice: widget.choice,
                                          ink: AppColors.inkPrimary,
                                          accent: _accent,
                                          blush: AppColors.accentBlush,
                                          pulse: _pulseController,
                                        ),
                                      )
                                    : SketchAnimation(
                                        painter: _CyberEmojiFacePainter(
                                          choice: widget.choice,
                                          ink: AppColors.inkPrimary,
                                          accent: _accent,
                                          blush: AppColors.accentBlush,
                                          pulse: _pulseController,
                                        ),
                                        backend: widget.animationBackend!,
                                        active: _focused,
                                        fallbackKey: EmojiFace.canvasKeyFor(
                                          widget.choice,
                                        ),
                                      ),
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
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _focused ? _accent : AppColors.paperBackground,
                          border: Border.all(
                            color: _focused ? _accent : AppColors.paperShadow,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          EmojiFace.visibleLabelFor(widget.choice),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            color: _focused
                                ? AppColors.paperBackground
                                : AppColors.inkPrimary,
                          ),
                        ),
                      )
                      .animate(target: _focused ? 1 : 0)
                      .moveY(begin: 0, end: -2, duration: 150.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CyberEmojiFacePainter extends CustomPainter {
  _CyberEmojiFacePainter({
    required this.choice,
    required this.ink,
    required this.accent,
    required this.blush,
    required this.pulse,
  }) : super(repaint: pulse);

  final EmojiChoice choice;
  final Color ink;
  final Color accent;
  final Color blush;
  final Animation<double> pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final wave = (pulse.value - 0.5) * 2;

    // Brutalist corner brackets & neon backing block.
    final frameRect = Rect.fromCenter(
      center: center,
      width: side * 0.72,
      height: side * 0.72,
    );
    canvas.drawRect(
      frameRect.shift(Offset(side * 0.03, side * 0.03)),
      Paint()
        ..color = accent.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );

    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.022
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    canvas.drawRect(frameRect, stroke);

    final eyeY = center.dy - side * 0.08 + wave * side * 0.012;
    final leftEye = Offset(center.dx - side * 0.15, eyeY);
    final rightEye = Offset(center.dx + side * 0.15, eyeY);

    if (choice == EmojiChoice.satisfied) {
      _drawCyberArcEye(canvas, leftEye, side, accent);
      _drawCyberArcEye(canvas, rightEye, side, accent);
      canvas.drawCircle(
        Offset(center.dx - side * 0.24, center.dy + side * 0.07),
        side * 0.045,
        Paint()..color = blush.withValues(alpha: 0.65),
      );
      canvas.drawCircle(
        Offset(center.dx + side * 0.24, center.dy + side * 0.07),
        side * 0.045,
        Paint()..color = blush.withValues(alpha: 0.65),
      );
    } else {
      final eyePaint = Paint()..color = accent;
      canvas.drawRect(
        Rect.fromCenter(
          center: leftEye,
          width: side * 0.065,
          height: side * 0.065,
        ),
        eyePaint,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: rightEye,
          width: side * 0.065,
          height: side * 0.065,
        ),
        eyePaint,
      );
    }

    _drawMouth(canvas, center, side, stroke);
  }

  void _drawCyberArcEye(Canvas canvas, Offset eye, double side, Color color) {
    final w = side * 0.12;
    final path = Path()
      ..moveTo(eye.dx - w / 2, eye.dy + w * 0.12)
      ..quadraticBezierTo(
        eye.dx,
        eye.dy - w * 0.45,
        eye.dx + w / 2,
        eye.dy + w * 0.12,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.025
        ..strokeCap = StrokeCap.square,
    );
  }

  void _drawMouth(Canvas canvas, Offset center, double side, Paint stroke) {
    final halfWidth = side * 0.15;
    final mouthY = center.dy + side * 0.12;
    final path = Path();

    switch (choice) {
      case EmojiChoice.satisfied:
        path
          ..moveTo(center.dx - halfWidth, mouthY)
          ..quadraticBezierTo(
            center.dx,
            mouthY + side * 0.15,
            center.dx + halfWidth,
            mouthY,
          );
      case EmojiChoice.neutral:
        path
          ..moveTo(center.dx - halfWidth, mouthY + side * 0.02)
          ..lineTo(center.dx + halfWidth, mouthY + side * 0.02);
      case EmojiChoice.dissatisfied:
        path
          ..moveTo(center.dx - halfWidth, mouthY + side * 0.08)
          ..quadraticBezierTo(
            center.dx,
            mouthY - side * 0.09,
            center.dx + halfWidth,
            mouthY + side * 0.08,
          );
    }

    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _CyberEmojiFacePainter oldDelegate) =>
      oldDelegate.choice != choice ||
      oldDelegate.ink != ink ||
      oldDelegate.accent != accent ||
      oldDelegate.blush != blush ||
      oldDelegate.pulse != pulse;
}
