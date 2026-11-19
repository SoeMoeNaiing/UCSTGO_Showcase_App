import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class _IncrementScoreIntent extends Intent {
  const _IncrementScoreIntent();
}

class _DecrementScoreIntent extends Intent {
  const _DecrementScoreIntent();
}

/// Five hand-drawn stars for rating a showcase project 1–5 (§10.7, §5.1).
///
/// Tapping a star draws it in and scores that many stars; D-pad left/right
/// adjusts the score (clamped, so the ends are no-ops). Internal state keeps
/// the widget reusable; [onChanged] lets the I28 controller observe it.
class RatingWidget extends StatefulWidget {
  const RatingWidget({
    super.key,
    this.initialScore = 0,
    this.onChanged,
    this.autofocusFirst = false,
  });

  /// Starting score; 0 means "not rated yet".
  final int initialScore;

  /// Called once whenever the score actually changes.
  final ValueChanged<int>? onChanged;

  /// Focus the first star after the first frame (TV / I29).
  final bool autofocusFirst;

  static const starCount = 5;

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  late int _score;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _score = widget.initialScore.clamp(0, RatingWidget.starCount);
    _nodes = List.generate(
      RatingWidget.starCount,
      (_) => FocusNode(debugLabel: 'rating-star'),
    );
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _setScore(int value) {
    final next = value.clamp(0, RatingWidget.starCount);
    if (next == _score) {
      return;
    }
    setState(() => _score = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Rating: $_score of ${RatingWidget.starCount}',
      child: FocusableActionDetector(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowRight):
              _IncrementScoreIntent(),
          SingleActivator(LogicalKeyboardKey.arrowLeft):
              _DecrementScoreIntent(),
        },
        actions: {
          _IncrementScoreIntent: CallbackAction<_IncrementScoreIntent>(
            onInvoke: (_) {
              _setScore(_score + 1);
              return null;
            },
          ),
          _DecrementScoreIntent: CallbackAction<_DecrementScoreIntent>(
            onInvoke: (_) {
              _setScore(_score - 1);
              return null;
            },
          ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Five 88dp stars need 440dp; a 360dp phone cannot fit them.
            final raw = (constraints.maxWidth - AppSpacing.sm * 4) / 5;
            final starSize = raw.isFinite
                ? raw.clamp(56.0, 88.0).toDouble()
                : 88.0;

            return SizedBox(
              // §5.5: a focusable control must be at least 120dp tall on TV.
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var star = 1; star <= RatingWidget.starCount; star++)
                    _SketchStar(
                      number: star,
                      size: starSize,
                      selected: _score >= star,
                      onTap: () => _setScore(star),
                      focusNode: _nodes[star - 1],
                      autofocus: widget.autofocusFirst && star == 1,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One star: a progressive sketch draw-in plus an elastic selection pop.
class _SketchStar extends StatefulWidget {
  const _SketchStar({
    required this.number,
    required this.size,
    required this.selected,
    required this.onTap,
    required this.focusNode,
    this.autofocus = false,
  });

  final int number;
  final double size;
  final bool selected;
  final VoidCallback onTap;
  final FocusNode focusNode;
  final bool autofocus;

  @override
  State<_SketchStar> createState() => _SketchStarState();
}

class _SketchStarState extends State<_SketchStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _draw,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    if (widget.selected) {
      _draw.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _SketchStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected == oldWidget.selected) {
      return;
    }
    if (widget.selected) {
      _draw.forward(from: 0);
    } else {
      _draw.value = 0;
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Rate ${widget.number} stars',
      selected: widget.selected,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: widget.selected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: SizedBox.square(
            dimension: widget.size,
            child: InkWell(
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: CustomPaint(
                painter: _StarPainter(
                  progress: _progress.value,
                  ink: AppColors.inkPrimary,
                  gold: AppColors.idleGlow,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a wobbly five-point star with a faint second pencil pass.
class _StarPainter extends CustomPainter {
  const _StarPainter({
    required this.progress,
    required this.ink,
    required this.gold,
  });

  final double progress;
  final Color ink;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _starPath(size);

    // Every star is visible, selected or not — only the gold fill draws in.
    canvas.save();
    canvas.translate(1, 1);
    canvas.drawPath(
      path,
      Paint()
        ..color = ink.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    if (progress > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = gold.withValues(alpha: 0.55 * progress)
          ..style = PaintingStyle.fill,
      );

      // A fat pencil stroke walks around the star, filling it in.
      final fill = Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(
          metric.extractPath(0, metric.length * progress),
          fill,
        );
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _starPath(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.shortestSide * 0.44;
    final inner = outer * 0.45;
    final path = Path();

    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? outer : inner;
      final wobble = 1 + 0.04 * math.sin(i * 2.7);
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
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ink != ink ||
      oldDelegate.gold != gold;
}
