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

class _RankedProject {
  const _RankedProject({
    required this.project,
    required this.avgScore,
    required this.voteCount,
  });

  final ShowcaseProject project;
  final double avgScore;
  final int voteCount;
}

class ShowcaseHomeScreen extends ConsumerStatefulWidget {
  const ShowcaseHomeScreen({super.key});

  @override
  ConsumerState<ShowcaseHomeScreen> createState() => _ShowcaseHomeScreenState();
}

class _ShowcaseHomeScreenState extends ConsumerState<ShowcaseHomeScreen> {
  String _selectedTrack = 'ALL';
  int _refreshTick = 0;

  Future<void> _openProjectDetail(ShowcaseProject project) async {
    await showMaximalistPopDialog<void>(
      context: context,
      borderColor: project.accent,
      shadowColor: AppColors.electricCyan,
      builder: (dialogContext) => _ProjectDetailDialog(project: project),
    );
    if (mounted) {
      setState(() => _refreshTick++);
    }
  }

  Future<List<_RankedProject>> _buildLeaderboard(
    AppDatabase db,
    List<ShowcaseProject> projects,
  ) async {
    final ratings = await db.getUnsyncedRatings();
    final byProject = <String, List<int>>{};
    for (final r in ratings) {
      (byProject[r.projectId] ??= []).add(r.score);
    }

    final ranked = [
      for (final p in projects)
        () {
          final scores = byProject[p.id] ?? const <int>[];
          final avg = scores.isEmpty
              ? 0.0
              : scores.fold<int>(0, (a, b) => a + b) / scores.length;
          return _RankedProject(
            project: p,
            avgScore: avg,
            voteCount: scores.length,
          );
        }(),
    ];

    ranked.sort((a, b) {
      final scoreCmp = b.avgScore.compareTo(a.avgScore);
      if (scoreCmp != 0) {
        return scoreCmp;
      }
      return b.voteCount.compareTo(a.voteCount);
    });
    return ranked;
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

    return Scaffold(
      body: MaximalistBackdrop(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView(
                    key: ValueKey('arcade_board_$_refreshTick'),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      96,
                    ),
                    children: [
                      const UniversityHeroBanner(),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          const Icon(
                                Icons.emoji_events_rounded,
                                color: AppColors.solarGold,
                                size: 26,
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scaleXY(
                                begin: 0.92,
                                end: 1.14,
                                duration: 900.ms,
                              ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'LIVE LEADERBOARD',
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 22,
                                color: AppColors.solarGold,
                              ),
                            ),
                          ),
                          Text(
                            'TAP TO VOTE',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.acidLime,
                              fontSize: 11,
                            ),
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
                              onSelected: (_) =>
                                  setState(() => _selectedTrack = track),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FutureBuilder<List<_RankedProject>>(
                        future: _buildLeaderboard(db, filtered),
                        builder: (context, snapshot) {
                          final ranked =
                              snapshot.data ??
                              [
                                for (final p in filtered)
                                  _RankedProject(
                                    project: p,
                                    avgScore: 0.0,
                                    voteCount: 0,
                                  ),
                              ];

                          return Column(
                            children: [
                              for (var i = 0; i < ranked.length; i++) ...[
                                _ArcadeScoreRow(
                                  rank: i + 1,
                                  item: ranked[i],
                                  onTap: () => unawaited(
                                    _openProjectDetail(ranked[i].project),
                                  ),
                                ),
                                if (i < ranked.length - 1)
                                  const SizedBox(height: AppSpacing.md),
                              ],
                            ],
                          );
                        },
                      ),
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

class _ArcadeScoreRow extends StatelessWidget {
  const _ArcadeScoreRow({
    required this.rank,
    required this.item,
    required this.onTap,
  });

  final int rank;
  final _RankedProject item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final project = item.project;
    final isFirst = rank == 1;
    final fillRatio = (item.avgScore / 5.0).clamp(0.0, 1.0);
    final rankColor = switch (rank) {
      1 => AppColors.solarGold,
      2 => AppColors.electricCyan,
      3 => AppColors.acidLime,
      _ => project.accent,
    };

    return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isFirst ? AppColors.solarGold : project.accent,
                width: isFirst ? AppSpacing.borderThick : AppSpacing.borderThin,
              ),
              boxShadow: [
                BoxShadow(
                  color: rankColor.withValues(alpha: isFirst ? 0.38 : 0.2),
                  offset: Offset(isFirst ? 5 : 3, isFirst ? 5 : 3),
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
                      color: rankColor,
                      child: Text(
                        isFirst ? '#1 LEADER' : '#$rank',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.voidBlack,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        project.track,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.inkSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      item.voteCount == 0
                          ? 'NO VOTES YET'
                          : '${item.avgScore.toStringAsFixed(1)} ★ (${item.voteCount})',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.solarGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  project.title,
                  style: textTheme.titleLarge?.copyWith(fontSize: 19),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  project.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    color: AppColors.surfaceElevated,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: fillRatio > 0 ? fillRatio : 0.06,
                      child: Container(color: rankColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: ((rank - 1) * 70).ms, duration: 260.ms)
        .slideX(begin: -0.04, end: 0, delay: ((rank - 1) * 70).ms);
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
          'VOTE FOR THIS PROJECT',
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
          child: Text(_submitting ? 'SAVING...' : 'SUBMIT VOTE'),
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
