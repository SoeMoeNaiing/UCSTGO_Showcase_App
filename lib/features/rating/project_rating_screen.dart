import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/showcase_providers.dart';
import '../../core/services/cooldown_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/pop_modal.dart';

const _svgStarFilled = '''
<svg viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2.5l2.95 6.08 6.7.97-4.85 4.72 1.15 6.68L12 17.77l-5.95 3.18 1.14-6.68L2.35 9.55l6.7-.97L12 2.5z"/>
</svg>
''';

const _svgStarOutline = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2.5l2.95 6.08 6.7.97-4.85 4.72 1.15 6.68L12 17.77l-5.95 3.18 1.14-6.68L2.35 9.55l6.7-.97L12 2.5z"/>
</svg>
''';

class _ProjectScoreStat {
  const _ProjectScoreStat({required this.avg, required this.count});

  final double avg;
  final int count;
}

class ProjectRatingScreen extends ConsumerStatefulWidget {
  const ProjectRatingScreen({super.key});

  @override
  ConsumerState<ProjectRatingScreen> createState() =>
      _ProjectRatingScreenState();
}

class _ProjectRatingScreenState extends ConsumerState<ProjectRatingScreen> {
  String _selectedTrack = 'ALL';
  int _refreshTick = 0;
  Timer? _idleHomeTimer;

  @override
  void initState() {
    super.initState();
    _resetIdleHomeTimer();
  }

  void _resetIdleHomeTimer() {
    _idleHomeTimer?.cancel();
    _idleHomeTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).maybePop();
      context.go('/');
    });
  }

  @override
  void dispose() {
    _idleHomeTimer?.cancel();
    super.dispose();
  }

  Future<void> _openRatingModal(ShowcaseProject project) async {
    _resetIdleHomeTimer();
    await showMaximalistPopDialog<void>(
      context: context,
      borderColor: project.accent,
      shadowColor: AppColors.electricCyan,
      builder: (dialogContext) => _GlassRatingDialog(project: project),
    );
    if (mounted) {
      _resetIdleHomeTimer();
      setState(() => _refreshTick++);
    }
  }

  Future<dynamic> _loadProjectScores(AppDatabase db) async {
    final ratings = await db.getUnsyncedRatings();
    final grouped = <String, List<int>>{};
    for (final r in ratings) {
      (grouped[r.projectId] ??= []).add(r.score);
    }
    final result = <String, _ProjectScoreStat>{};
    for (final entry in grouped.entries) {
      final sum = entry.value.fold<int>(0, (a, b) => a + b);
      result[entry.key] = _ProjectScoreStat(
        avg: sum / entry.value.length,
        count: entry.value.length,
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final allProjects = ref.watch(showcaseProjectsProvider);
    final db = ref.watch(appDatabaseProvider);
    final tracks = <String>[
      'ALL',
      ...{for (final p in allProjects) p.track},
    ];
    final filtered = _selectedTrack == 'ALL'
        ? allProjects
        : allProjects.where((p) => p.track == _selectedTrack).toList();
    final textTheme = Theme.of(context).textTheme;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetIdleHomeTimer(),
      onPointerMove: (_) => _resetIdleHomeTimer(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) {
          _resetIdleHomeTimer();
          return false;
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF070A12),
          body: SafeArea(
            child: FutureBuilder(
              key: ValueKey('glass_rating_$_refreshTick'),
              future: _loadProjectScores(db),
              builder: (context, snapshot) {
                final scoresMap =
                    (snapshot.data as Map<String, _ProjectScoreStat>?) ??
                    const <String, _ProjectScoreStat>{};

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/'),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'STEP 02 // PROJECT RATINGS',
                            style: textTheme.labelLarge?.copyWith(
                              fontFamily: 'monospace',
                              color: AppColors.electricCyan,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ExpandableRatingLeaderboard(
                      projects: allProjects,
                      scoresById: scoresMap,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Rate Student Projects',
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap any project to cast a 1-5 star rating and rate as many booths as you like.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tracks.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          final selected = track == _selectedTrack;
                          return GestureDetector(
                            onTap: () {
                              _resetIdleHomeTimer();
                              setState(() => _selectedTrack = track);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.electricCyan.withValues(
                                        alpha: 0.2,
                                      )
                                    : const Color(0xFF101726)
                                          .withValues(alpha: 0.78),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.electricCyan
                                      : Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: Text(
                                track,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? AppColors.electricCyan
                                      : Colors.white70,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < filtered.length; i++) ...[
                      _GlassProjectCard(
                        project: filtered[i],
                        stat: scoresMap[filtered[i].id],
                        onRate: () => unawaited(_openRatingModal(filtered[i])),
                      ),
                      if (i < filtered.length - 1)
                        const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandableRatingLeaderboard extends StatefulWidget {
  const _ExpandableRatingLeaderboard({
    required this.projects,
    required this.scoresById,
  });

  final List<ShowcaseProject> projects;
  final Map<String, _ProjectScoreStat> scoresById;

  @override
  State<_ExpandableRatingLeaderboard> createState() =>
      _ExpandableRatingLeaderboardState();
}

class _ExpandableRatingLeaderboardState
    extends State<_ExpandableRatingLeaderboard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sorted = List<ShowcaseProject>.from(widget.projects)
      ..sort((a, b) {
        final sa = widget.scoresById[a.id];
        final sb = widget.scoresById[b.id];
        final avgA = sa?.avg ?? 0.0;
        final avgB = sb?.avg ?? 0.0;
        if (avgB.compareTo(avgA) != 0) {
          return avgB.compareTo(avgA);
        }
        return (sb?.count ?? 0).compareTo(sa?.count ?? 0);
      });

    final visibleRows = _expanded ? sorted : sorted.take(3).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFF101726).withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.electricCyan.withValues(alpha: 0.35),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactHeader = constraints.maxWidth < 360;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.electricCyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              compactHeader
                                  ? 'LIVE STANDINGS'
                                  : 'LIVE STANDINGS // LEADERBOARD',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.electricCyan,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _expanded
                                ? 'COLLAPSE'
                                : 'EXPAND (${sorted.length})',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        for (var idx = 0; idx < visibleRows.length; idx++) ...[
                          _LeaderboardRankRow(
                            rank: idx + 1,
                            project: visibleRows[idx],
                            stat: widget.scoresById[visibleRows[idx].id],
                          ),
                          if (idx < visibleRows.length - 1)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LeaderboardRankRow extends StatelessWidget {
  const _LeaderboardRankRow({
    required this.rank,
    required this.project,
    required this.stat,
  });

  final int rank;
  final ShowcaseProject project;
  final _ProjectScoreStat? stat;

  @override
  Widget build(BuildContext context) {
    final hasVotes = stat != null && stat!.count > 0;
    final avgText = hasVotes ? stat!.avg.toStringAsFixed(1) : '0.0';
    final countText = '${stat?.count ?? 0}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 330;
          return Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: rank == 1 ? AppColors.solarGold : project.accent,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      narrow
                          ? '${project.track} • $countText votes'
                          : project.track,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.string(
                      _svgStarFilled,
                      width: 12,
                      height: 12,
                      colorFilter: ColorFilter.mode(
                        hasVotes ? AppColors.solarGold : Colors.white38,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      narrow ? avgText : '$avgText ($countText)',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlassProjectCard extends StatelessWidget {
  const _GlassProjectCard({
    required this.project,
    required this.stat,
    required this.onRate,
  });

  final ShowcaseProject project;
  final _ProjectScoreStat? stat;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasVotes = stat != null && stat!.count > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFF101726).withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: project.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        project.track,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: project.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SvgPicture.string(
                    _svgStarFilled,
                    width: 14,
                    height: 14,
                    colorFilter: const ColorFilter.mode(
                      AppColors.solarGold,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasVotes
                        ? '${stat!.avg.toStringAsFixed(1)} (${stat!.count})'
                        : '0.0 (0)',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.title,
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                project.team,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 8),
              Text(
                project.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: project.accent,
                    foregroundColor: AppColors.voidBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onRate,
                  child: const Text(
                    'RATE PROJECT',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassRatingDialog extends ConsumerStatefulWidget {
  const _GlassRatingDialog({required this.project});

  final ShowcaseProject project;

  @override
  ConsumerState<_GlassRatingDialog> createState() => _GlassRatingDialogState();
}

class _GlassRatingDialogState extends ConsumerState<_GlassRatingDialog> {
  int _stars = 0;
  bool _submitting = false;
  String? _statusLine;
  Color _statusColor = AppColors.acidLime;

  Future<void> _submitRating() async {
    if (_submitting || _stars < 1) {
      return;
    }

    final scope = CooldownService.ratingProjectScope(widget.project.id);
    final cooldown = ref.read(cooldownServiceProvider);
    final remaining = cooldown.remaining(scope);
    if (remaining > Duration.zero) {
      setState(() {
        _statusColor = AppColors.solarGold;
        _statusLine = 'COOLDOWN ACTIVE: WAIT ${remaining.inSeconds + 1}S';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _statusLine = null;
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
        _statusColor = AppColors.acidLime;
        _statusLine = report.totalSynced > 0
            ? 'RATED $_stars/5 & SYNCED TO SHEETS'
            : 'RATED $_stars/5 — SAVED LOCALLY';
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
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: project.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  project.track,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: project.accent,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          project.title,
          style: textTheme.headlineMedium?.copyWith(
            fontSize: 21,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          project.team,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 10),
        Text(
          project.summary,
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var s = 1; s <= 5; s++)
              GestureDetector(
                onTap: _submitting ? null : () => setState(() => _stars = s),
                child:
                    Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SvgPicture.string(
                            s <= _stars ? _svgStarFilled : _svgStarOutline,
                            width: 34,
                            height: 34,
                            colorFilter: ColorFilter.mode(
                              s <= _stars
                                  ? AppColors.solarGold
                                  : Colors.white38,
                              BlendMode.srcIn,
                            ),
                          ),
                        )
                        .animate(target: s <= _stars ? 1 : 0)
                        .scaleXY(
                          begin: 1.0,
                          end: 1.18,
                          duration: 160.ms,
                          curve: Curves.easeOutBack,
                        ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: project.accent,
            foregroundColor: AppColors.voidBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: (!_submitting && _stars > 0)
              ? () => unawaited(_submitRating())
              : null,
          child: Text(
            _submitting ? 'SAVING...' : 'SUBMIT RATING',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (_statusLine != null) ...[
          const SizedBox(height: 10),
          Text(
            _statusLine!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _statusColor,
            ),
          ),
        ],
      ],
    );
  }
}