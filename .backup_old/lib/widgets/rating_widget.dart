import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

class _IncrementScoreIntent extends Intent {
  const _IncrementScoreIntent();
}

class _DecrementScoreIntent extends Intent {
  const _DecrementScoreIntent();
}

/// Cyber-Brutalist 5-star rating selector with staggered cascade on tap
/// and D-pad arrow support.
class RatingWidget extends StatefulWidget {
  const RatingWidget({
    super.key,
    this.initialScore = 0,
    this.onChanged,
    this.autofocusFirst = false,
  });

  final int initialScore;
  final ValueChanged<int>? onChanged;
  final bool autofocusFirst;

  static const starCount = 5;

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  late int _score;
  late int _visualScore;
  late final List<FocusNode> _nodes;
  Timer? _cascadeTimer;

  @override
  void initState() {
    super.initState();
    _score = widget.initialScore.clamp(0, RatingWidget.starCount);
    _visualScore = _score;
    _nodes = List.generate(
      RatingWidget.starCount,
      (_) => FocusNode(debugLabel: 'rating-star'),
    );
  }

  @override
  void dispose() {
    _cascadeTimer?.cancel();
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
    _cascadeTimer?.cancel();
    setState(() {
      _score = next;
      if (next < _visualScore) {
        _visualScore = next;
      }
    });
    widget.onChanged?.call(next);

    if (next > _visualScore) {
      var step = _visualScore + 1;
      _cascadeTimer = Timer.periodic(const Duration(milliseconds: 55), (timer) {
        if (!mounted || step > next) {
          timer.cancel();
          return;
        }
        setState(() => _visualScore = step);
        step++;
      });
    }
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
            final raw = (constraints.maxWidth - AppSpacing.sm * 4) / 5;
            final starSize = raw.isFinite
                ? raw.clamp(56.0, 88.0).toDouble()
                : 88.0;

            return SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var star = 1; star <= RatingWidget.starCount; star++)
                    _CyberStar(
                      number: star,
                      size: starSize,
                      selected: _visualScore >= star,
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

class _CyberStar extends StatefulWidget {
  const _CyberStar({
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
  State<_CyberStar> createState() => _CyberStarState();
}

class _CyberStarState extends State<_CyberStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
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
  void didUpdateWidget(covariant _CyberStar oldWidget) {
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
          scale: widget.selected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.elasticOut,
          child: SizedBox.square(
            dimension: widget.size,
            child: InkWell(
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppSpacing.xs),
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

    canvas.save();
    canvas.translate(2, 2);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accentWarm.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.restore();

    if (progress > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = gold.withValues(alpha: 0.65 * progress)
          ..style = PaintingStyle.fill,
      );

      final fill = Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.14
        ..strokeCap = StrokeCap.square;
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * progress), fill);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
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
      final point =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
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
