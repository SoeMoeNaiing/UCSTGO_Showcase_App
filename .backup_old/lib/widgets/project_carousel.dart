import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/project.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import './project_card.dart';

class _NextProjectIntent extends Intent {
  const _NextProjectIntent();
}

class _PreviousProjectIntent extends Intent {
  const _PreviousProjectIntent();
}

/// Cyber-Brutalist carousel preserving [pageViewKey], [dotsKey], D-pad
/// arrow navigation, and card focus management.
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
      return;
    }
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _cardNodes[index].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowRight): _NextProjectIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PreviousProjectIntent(),
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
                width: 170,
                height: 20,
                child: CustomPaint(
                  painter: _CyberTicksPainter(
                    count: widget.projects.length,
                    active: _index,
                    ink: AppColors.inkSecondary,
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

class _CyberTicksPainter extends CustomPainter {
  const _CyberTicksPainter({
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
    if (count <= 0) {
      return;
    }
    final step = size.width / (count + 1);
    for (var i = 0; i < count; i++) {
      final isActive = i == active;
      final cx = step * (i + 1);
      final cy = size.height / 2 + math.sin(i.toDouble()) * 1.5;
      final w = isActive ? 18.0 : 10.0;
      final h = isActive ? 8.0 : 6.0;
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
      canvas.drawRect(
        rect,
        Paint()
          ..color = isActive ? accent : ink.withValues(alpha: 0.45)
          ..style = isActive ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CyberTicksPainter oldDelegate) =>
      oldDelegate.count != count ||
      oldDelegate.active != active ||
      oldDelegate.ink != ink ||
      oldDelegate.accent != accent;
}
