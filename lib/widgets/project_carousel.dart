import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../models/project.dart';
import './project_card.dart';

class _NextProjectIntent extends Intent {
  const _NextProjectIntent();
}

class _PreviousProjectIntent extends Intent {
  const _PreviousProjectIntent();
}

/// Swipeable showcase projects with D-pad next/prev and sketch page dots
/// (§10.7, §2.3.2).
///
/// Focus follows the visible page: the carousel owns a `FocusNode` per card
/// and hands focus to the new page after a swipe or arrow key. Arrow actions
/// are clamped, so the first/last card is never a focus trap.
class ProjectCarousel extends StatefulWidget {
  const ProjectCarousel({
    super.key,
    required this.projects,
    required this.onSelect,
    this.initialIndex = 0,
    this.viewportHeight = 340,
  });

  final List<Project> projects;
  final ValueChanged<Project> onSelect;
  final int initialIndex;
  final double viewportHeight;

  static const pageViewKey = Key('project_carousel_pages');
  static const dotsKey = Key('project_carousel_dots');

  @override
  State<ProjectCarousel> createState() => _ProjectCarouselState();
}

class _ProjectCarouselState extends State<ProjectCarousel> {
  late final PageController _pages;
  late final List<FocusNode> _cardNodes;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.projects.length - 1);
    _pages = PageController(initialPage: _index);
    _cardNodes = List.generate(widget.projects.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    _pages.dispose();
    for (final node in _cardNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _goTo(int target) {
    final next = target.clamp(0, widget.projects.length - 1);
    if (next == _index) {
      return; // edge is a no-op, never a focus trap
    }
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    // The old card is now off-screen; move focus to the visible one.
    _cardNodes[index].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowRight): _NextProjectIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft):
            _PreviousProjectIntent(),
      },
      actions: {
        _NextProjectIntent: CallbackAction<_NextProjectIntent>(
          onInvoke: (_) {
            _goTo(_index + 1);
            return null;
          },
        ),
        _PreviousProjectIntent: CallbackAction<_PreviousProjectIntent>(
          onInvoke: (_) {
            _goTo(_index - 1);
            return null;
          },
        ),
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: widget.viewportHeight,
            child: PageView.builder(
              key: ProjectCarousel.pageViewKey,
              controller: _pages,
              itemCount: widget.projects.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) => Center(
                child: ProjectCard(
                  project: widget.projects[index],
                  onSelect: widget.onSelect,
                  autofocus: index == _index,
                  focusNode: _cardNodes[index],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: 'Project ${_index + 1} of ${widget.projects.length}',
            child: ExcludeSemantics(
              child: SizedBox(
                key: ProjectCarousel.dotsKey,
                width: 160,
                height: 18,
                child: CustomPaint(
                  painter: _PageDotsPainter(
                    count: widget.projects.length,
                    active: _index,
                    ink: AppColors.inkPrimary,
                    accent: AppColors.accentWarm,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hand-drawn page dots: wobbly ellipses, the active one filled with the
/// warm accent. No animation controller — cheap on a low-end TV (§2.3.3).
class _PageDotsPainter extends CustomPainter {
  const _PageDotsPainter({
    required this.count,
    required this.active,
    required this.ink,
    required this.accent,
  });

  final int count;
  final int active;
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final spacing = size.width / (count + 1);

    for (var i = 0; i < count; i++) {
      final isActive = i == active;
      final center = Offset(
        spacing * (i + 1),
        size.height / 2 + (i.isEven ? 1 : -1),
      );
      final radius = isActive ? 6.0 : 4.0;
      final path = Path();
      const steps = 16;

      for (var step = 0; step <= steps; step++) {
        final angle = 2 * math.pi * step / steps;
        final wobble = 1 + 0.08 * math.sin(3 * angle + i);
        final point = center +
            Offset(
              math.cos(angle) * radius * wobble,
              math.sin(angle) * radius * wobble,
            );
        if (step == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      canvas.drawPath(
        path..close(),
        Paint()
          ..color = isActive ? accent : ink.withValues(alpha: 0.4)
          ..style = isActive ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PageDotsPainter oldDelegate) =>
      oldDelegate.count != count ||
      oldDelegate.active != active ||
      oldDelegate.ink != ink ||
      oldDelegate.accent != accent;
}
