import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/showcase_providers.dart';
import '../../core/services/cooldown_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/hanging_feedback_button.dart';
import '../../core/widgets/live_ticker_bar.dart';
import '../../core/widgets/maximalist_backdrop.dart';
import '../../core/widgets/pop_modal.dart';
import '../../core/widgets/university_hero_banner.dart';

class ShowcaseHomeScreen extends ConsumerStatefulWidget {
  const ShowcaseHomeScreen({super.key});

  @override
  ConsumerState<ShowcaseHomeScreen> createState() => _ShowcaseHomeScreenState();
}

class _ShowcaseHomeScreenState extends ConsumerState<ShowcaseHomeScreen>
    with SingleTickerProviderStateMixin {
  String _selectedTrack = 'ALL';
  int _activeIndex = 0;
  double _dragDx = 0;
  bool _autoCycle = true;
  int _refreshTick = 0;
  Timer? _cycleTimer;
  late final AnimationController _snapController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  double _snapStartDx = 0;

  @override
  void initState() {
    super.initState();
    _snapController.addListener(_onSnapTick);
    _restartAutoCycle();
  }

  void _onSnapTick() {
    final curved = Curves.easeOutBack.transform(_snapController.value);
    setState(() {
      _dragDx = _snapStartDx * (1.0 - curved);
    });
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _snapController.removeListener(_onSnapTick);
    _snapController.dispose();
    super.dispose();
  }

  void _restartAutoCycle() {
    _cycleTimer?.cancel();
    if (!_autoCycle) {
      return;
    }
    _cycleTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) {
        return;
      }
      final list = _currentFilteredProjects();
      if (list.length > 1 &&
          _dragDx.abs() < 1 &&
          !_snapController.isAnimating) {
        setState(() {
          _activeIndex = (_activeIndex + 1) % list.length;
        });
      }
    });
  }

  List<ShowcaseProject> _currentFilteredProjects() {
    final projects = ref.read(showcaseProjectsProvider);
    if (_selectedTrack == 'ALL') {
      return projects;
    }
    final matches = projects.where((p) => p.track == _selectedTrack).toList();
    return matches.isEmpty ? projects : matches;
  }

  void _animateSnapBack() {
    if (_dragDx == 0) {
      return;
    }
    _snapStartDx = _dragDx;
    _snapController.forward(from: 0);
  }

  void _stepDeck(int delta, int total) {
    if (total <= 0) {
      return;
    }
    _snapController.stop();
    setState(() {
      _dragDx = 0;
      _activeIndex = (_activeIndex + delta + total) % total;
    });
  }

  Future<void> _openProjectDetail(ShowcaseProject project) async {
    final wasAuto = _autoCycle;
    if (wasAuto) {
      setState(() => _autoCycle = false);
      _restartAutoCycle();
    }

    await showMaximalistPopDialog<void>(
      context: context,
      borderColor: project.accent,
      shadowColor: AppColors.electricCyan,
      builder: (dialogContext) => _ProjectDetailDialog(project: project),
    );

    if (mounted) {
      setState(() {
        _refreshTick++;
        _autoCycle = wasAuto;
      });
      _restartAutoCycle();
    }
  }

  Future<({int ratingCount, double avgScore})> _loadRatingStats(
    AppDatabase db,
  ) async {
    final unsynced = await db.getUnsyncedRatings();
    if (unsynced.isEmpty) {
      return (ratingCount: 0, avgScore: 0.0);
    }
    final total = unsynced.fold<int>(0, (sum, r) => sum + r.score);
    return (ratingCount: unsynced.length, avgScore: total / unsynced.length);
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(showcaseProjectsProvider);
    final db = ref.watch(appDatabaseProvider);
    final tracks = <String>[
      'ALL',
      ...{for (final p in projects) p.track},
    ];
    final filtered = _selectedTrack == 'ALL'
        ? projects
        : projects.where((p) => p.track == _selectedTrack).toList();
    final safeIndex = filtered.isEmpty
        ? 0
        : _activeIndex.clamp(0, filtered.length - 1);
    final activeProject = filtered.isEmpty ? null : filtered[safeIndex];
    final nextProject = filtered.length > 1
        ? filtered[(safeIndex + 1) % filtered.length]
        : null;
    final thirdProject = filtered.length > 2
        ? filtered[(safeIndex + 2) % filtered.length]
        : null;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: MaximalistBackdrop(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView(
                    key: ValueKey('stacked_deck_$_refreshTick'),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      96,
                    ),
                    children: [
                      const UniversityHeroBanner(),
                      const SizedBox(height: AppSpacing.md),
                      FutureBuilder<({int ratingCount, double avgScore})>(
                        future: _loadRatingStats(db),
                        builder: (context, snapshot) {
                          final stats =
                              snapshot.data ?? (ratingCount: 0, avgScore: 0.0);
                          final avgLabel = stats.ratingCount == 0
                              ? '--'
                              : stats.avgScore.toStringAsFixed(1);
                          return Row(
                            children: [
                              Expanded(
                                child: _DeckStatPill(
                                  label: 'PROJECTS',
                                  value: '${projects.length}',
                                  accent: AppColors.electricCyan,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _DeckStatPill(
                                  label: 'AVG SCORE',
                                  value: stats.ratingCount == 0
                                      ? avgLabel
                                      : '$avgLabel ★ (${stats.ratingCount})',
                                  accent: AppColors.solarGold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'STACKED DECK',
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 22,
                              ),
                            ),
                          ),
                          FilterChip(
                            selected: _autoCycle,
                            label: Text(_autoCycle ? 'AUTO: ON' : 'AUTO: OFF'),
                            onSelected: (val) {
                              setState(() => _autoCycle = val);
                              _restartAutoCycle();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: tracks.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final track = tracks[index];
                            final active = track == _selectedTrack;
                            return ChoiceChip(
                              selected: active,
                              label: Text(track),
                              onSelected: (_) {
                                _snapController.stop();
                                setState(() {
                                  _selectedTrack = track;
                                  _activeIndex = 0;
                                  _dragDx = 0;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (activeProject != null) ...[
                        _StackedCardStage(
                          activeProject: activeProject,
                          nextProject: nextProject,
                          thirdProject: thirdProject,
                          activeIndex: safeIndex,
                          dragDx: _dragDx,
                          onPanStart: (_) {
                            _snapController.stop();
                            if (_autoCycle) {
                              setState(() => _autoCycle = false);
                              _restartAutoCycle();
                            }
                          },
                          onPanUpdate: (details) {
                            setState(() => _dragDx += details.delta.dx);
                          },
                          onPanEnd: (_) {
                            if (_dragDx > 95) {
                              _stepDeck(1, filtered.length);
                            } else if (_dragDx < -95) {
                              _stepDeck(-1, filtered.length);
                            } else {
                              _animateSnapBack();
                            }
                          },
                          onInspect: () =>
                              unawaited(_openProjectDetail(activeProject)),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filledTonal(
                              onPressed: () => _stepDeck(-1, filtered.length),
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'DRAG TO PEEK • ${safeIndex + 1} / ${filtered.length}',
                              style: textTheme.labelLarge,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            IconButton.filledTonal(
                              onPressed: () => _stepDeck(1, filtered.length),
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (var i = 0; i < filtered.length; i++) ...[
                          _AnimatedQueueRow(
                            project: filtered[i],
                            selected: i == safeIndex,
                            index: i,
                            onSelect: () {
                              _snapController.stop();
                              setState(() {
                                _activeIndex = i;
                                _dragDx = 0;
                              });
                            },
                            onOpen: () =>
                                unawaited(_openProjectDetail(filtered[i])),
                          ),
                          if (i < filtered.length - 1)
                            const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ],
                  ),
                ),
                const LiveTickerBar(),
              ],
            ),
            Positioned(
              right: AppSpacing.md,
              bottom: 52,
              child: HangingFeedbackButton(
                onPressed: () => context.go('/feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StackedCardStage extends StatelessWidget {
  const _StackedCardStage({
    required this.activeProject,
    required this.nextProject,
    required this.thirdProject,
    required this.activeIndex,
    required this.dragDx,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onInspect,
  });

  final ShowcaseProject activeProject;
  final ShowcaseProject? nextProject;
  final ShowcaseProject? thirdProject;
  final int activeIndex;
  final double dragDx;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) {
    final pullProgress = (dragDx.abs() / 140).clamp(0.0, 1.0);
    final topTilt = (dragDx / 420).clamp(-0.14, 0.14);
    // Under-card tilts subtly into view as top card pulls away.
    final underTilt = (-dragDx / 950).clamp(-0.045, 0.045);
    final underScale = 0.94 + (0.06 * pullProgress);
    final underOffsetY = 14.0 * (1.0 - pullProgress);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (thirdProject != null)
          Transform.translate(
            offset: const Offset(0, 24),
            child: Transform.scale(
              scale: 0.89,
              alignment: Alignment.topCenter,
              child: Opacity(
                opacity: 0.45,
                child: _ProjectDeckCardBody(
                  project: thirdProject!,
                  compactPreview: true,
                ),
              ),
            ),
          ),
        if (nextProject != null)
          Transform.translate(
            offset: Offset(dragDx * 0.12, underOffsetY),
            child: Transform.rotate(
              angle: underTilt,
              child: Transform.scale(
                scale: underScale,
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: (0.72 + (0.28 * pullProgress)).clamp(0.0, 1.0),
                  child: _ProjectDeckCardBody(
                    project: nextProject!,
                    compactPreview: true,
                  ),
                ),
              ),
            ),
          ),
        GestureDetector(
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              onTap: onInspect,
              child: Transform.translate(
                offset: Offset(dragDx, dragDx.abs() * 0.04),
                child: Transform.rotate(
                  angle: topTilt,
                  child: _ProjectDeckCardBody(
                    project: activeProject,
                    dragDx: dragDx,
                    onInspect: onInspect,
                  ),
                ),
              ),
            )
            .animate(
              key: ValueKey('stack_top_${activeProject.id}_$activeIndex'),
              onPlay: (c) => c.repeat(reverse: true),
            )
            .moveY(
              begin: -2.5,
              end: 2.5,
              duration: const Duration(milliseconds: 1800),
              curve: Curves.easeInOutSine,
            ),
      ],
    );
  }
}

class _ProjectDeckCardBody extends StatelessWidget {
  const _ProjectDeckCardBody({
    required this.project,
    this.dragDx = 0,
    this.compactPreview = false,
    this.onInspect,
  });

  final ShowcaseProject project;
  final double dragDx;
  final bool compactPreview;
  final VoidCallback? onInspect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: project.accent,
          width: AppSpacing.borderThick,
        ),
        boxShadow: [
          BoxShadow(
            color: project.accent.withValues(alpha: 0.38),
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                color: project.accent,
                child: Text(
                  project.track,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.voidBlack,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              if (!compactPreview && dragDx.abs() > 24)
                Text(
                  dragDx > 0 ? 'NEXT >>>' : '<<< PREV',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.acidLime,
                  ),
                )
              else
                Icon(
                  compactPreview ? Icons.layers_rounded : Icons.swipe_rounded,
                  color: project.accent,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            project.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineMedium?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            project.team,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(color: AppColors.solarGold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            project.summary,
            maxLines: compactPreview ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyLarge,
          ),
          if (!compactPreview) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final tag in project.techStack) Chip(label: Text(tag)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onInspect,
              icon: const Icon(Icons.star_rate_rounded),
              label: const Text('INSPECT & RATE'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeckStatPill extends StatelessWidget {
  const _DeckStatPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: accent, width: AppSpacing.borderThin),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.inkSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(color: accent, fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class _AnimatedQueueRow extends StatelessWidget {
  const _AnimatedQueueRow({
    required this.project,
    required this.selected,
    required this.index,
    required this.onSelect,
    required this.onOpen,
  });

  final ShowcaseProject project;
  final bool selected;
  final int index;
  final VoidCallback onSelect;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.surfaceElevated
              : AppColors.surfaceDark.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: selected ? project.accent : AppColors.gridLine,
            width: selected ? AppSpacing.borderThick : AppSpacing.borderThin,
          ),
        ),
        child: Row(
          children: [
            Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: project.accent,
                    shape: BoxShape.circle,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 0.85,
                  end: 1.35,
                  delay: (index * 150).ms,
                  duration: const Duration(milliseconds: 1100),
                ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge,
                  ),
                  Text(
                    project.track,
                    style: textTheme.bodyMedium?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onOpen,
              icon: Icon(Icons.open_in_new_rounded, color: project.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectDetailDialog extends ConsumerStatefulWidget {
  const _ProjectDetailDialog({required this.project});

  final ShowcaseProject project;

  @override
  ConsumerState<_ProjectDetailDialog> createState() =>
      _ProjectDetailDialogState();
}

class _ProjectDetailDialogState extends ConsumerState<_ProjectDetailDialog> {
  int _stars = 0;
  bool _submitting = false;
  String? _feedbackLine;
  Color _feedbackColor = AppColors.acidLime;

  Future<void> _rateProject() async {
    if (_submitting || _stars < 1) {
      return;
    }

    final scope = CooldownService.ratingProjectScope(widget.project.id);
    final cooldown = ref.read(cooldownServiceProvider);
    final remaining = cooldown.remaining(scope);
    if (remaining > Duration.zero) {
      setState(() {
        _feedbackColor = AppColors.solarGold;
        _feedbackLine =
            'COOLDOWN FOR ${widget.project.title.toUpperCase()}: WAIT ${remaining.inSeconds + 1}S';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _feedbackLine = null;
    });

    try {
      final db = ref.read(appDatabaseProvider);
      final deviceId = await ref
          .read(deviceIdServiceProvider)
          .getOrCreateDeviceId();

      await db.insertRating(
        eventId: 'rt-${const Uuid().v4()}',
        deviceId: deviceId,
        projectId: widget.project.id,
        projectTitle: widget.project.title,
        score: _stars,
      );

      cooldown.recordSubmission(scope);
      final report = await ref.read(sheetsSyncServiceProvider).syncPending();

      if (!mounted) {
        return;
      }

      setState(() {
        _feedbackColor = AppColors.acidLime;
        _feedbackLine = report.totalSynced > 0
            ? 'RATED $_stars/5 & SYNCED TO GOOGLE SHEETS!'
            : 'RATED $_stars/5 — SAVED TO LOCAL DB!';
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final project = widget.project;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              color: project.accent,
              child: Text(
                project.track,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.voidBlack,
                  fontSize: 11,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          project.title,
          style: textTheme.headlineMedium?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          project.team,
          style: textTheme.labelLarge?.copyWith(color: AppColors.solarGold),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(project.summary, style: textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final tag in project.techStack) Chip(label: Text(tag)),
          ],
        ),
        const Divider(height: AppSpacing.xl, color: AppColors.gridLine),
        Text(
          'RATE THIS PROJECT',
          textAlign: TextAlign.center,
          style: textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var s = 1; s <= 5; s++)
              IconButton(
                    iconSize: 36,
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _stars = s),
                    icon: Icon(
                      s <= _stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: s <= _stars
                          ? AppColors.solarGold
                          : AppColors.inkSecondary,
                    ),
                  )
                  .animate(target: s <= _stars ? 1 : 0)
                  .scaleXY(
                    begin: 1.0,
                    end: 1.2,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                  ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          onPressed: (!_submitting && _stars > 0)
              ? () => unawaited(_rateProject())
              : null,
          child: Text(_submitting ? 'SAVING...' : 'SUBMIT RATING'),
        ),
        if (_feedbackLine != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _feedbackLine!,
            textAlign: TextAlign.center,
            style: textTheme.labelLarge?.copyWith(color: _feedbackColor),
          ),
        ],
      ],
    );
  }
}
