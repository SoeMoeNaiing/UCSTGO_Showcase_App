import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

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

class _ShowcaseHomeScreenState extends ConsumerState<ShowcaseHomeScreen> {
  String _selectedTrack = 'ALL';

  Future<void> _openProjectDetail(ShowcaseProject project) async {
    await showMaximalistPopDialog<void>(
      context: context,
      borderColor: project.accent,
      shadowColor: AppColors.electricCyan,
      builder: (dialogContext) => _ProjectDetailDialog(project: project),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(showcaseProjectsProvider);
    final tracks = <String>[
      'ALL',
      ...{for (final p in projects) p.track},
    ];
    final filtered = _selectedTrack == 'ALL'
        ? projects
        : projects.where((p) => p.track == _selectedTrack).toList();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: MaximalistBackdrop(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView(
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
                          Expanded(
                            child: Text(
                              'EXPLORE PROJECTS',
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 22,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                              border: Border.all(color: AppColors.acidLime),
                            ),
                            child: Text(
                              '${filtered.length} LIVE',
                              style: textTheme.labelLarge?.copyWith(
                                color: AppColors.acidLime,
                                fontSize: 11,
                              ),
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
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 680;
                          if (isWide) {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: AppSpacing.md,
                                    crossAxisSpacing: AppSpacing.md,
                                    childAspectRatio: 1.45,
                                  ),
                              itemBuilder: (context, index) =>
                                  _ExploreProjectCard(
                                    project: filtered[index],
                                    index: index,
                                    onTap: () => unawaited(
                                      _openProjectDetail(filtered[index]),
                                    ),
                                  ),
                            );
                          }
                          return Column(
                            children: [
                              for (var i = 0; i < filtered.length; i++) ...[
                                _ExploreProjectCard(
                                  project: filtered[i],
                                  index: i,
                                  onTap: () => unawaited(
                                    _openProjectDetail(filtered[i]),
                                  ),
                                ),
                                if (i < filtered.length - 1)
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

class _ExploreProjectCard extends StatelessWidget {
  const _ExploreProjectCard({
    required this.project,
    required this.index,
    required this.onTap,
  });

  final ShowcaseProject project;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: project.accent,
                width: AppSpacing.borderThick,
              ),
              boxShadow: [
                BoxShadow(
                  color: project.accent.withValues(alpha: 0.35),
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                    Icon(
                      Icons.open_in_full_rounded,
                      size: 18,
                      color: project.accent,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  project.title,
                  style: textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  project.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final tag in project.techStack)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          border: Border.all(color: AppColors.gridLine),
                        ),
                        child: Text(
                          tag,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 70).ms, duration: 280.ms)
        .slideY(begin: 0.06, end: 0, delay: (index * 70).ms, duration: 280.ms);
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
