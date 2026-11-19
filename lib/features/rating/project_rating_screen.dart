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
import '../../core/widgets/live_ticker_bar.dart';
import '../../core/widgets/maximalist_backdrop.dart';

class ProjectRatingScreen extends ConsumerStatefulWidget {
  const ProjectRatingScreen({super.key});

  @override
  ConsumerState<ProjectRatingScreen> createState() =>
      _ProjectRatingScreenState();
}

class _ProjectRatingScreenState extends ConsumerState<ProjectRatingScreen> {
  int _selectedProjectIndex = 0;
  int _stars = 0;
  bool _submitting = false;
  String? _bannerText;
  Color _bannerColor = AppColors.acidLime;

  Future<void> _submitRating(ShowcaseProject project) async {
    if (_submitting || _stars < 1) {
      return;
    }

    final cooldown = ref.read(cooldownServiceProvider);
    final remaining = cooldown.remaining(CooldownService.ratingScope);
    if (remaining > Duration.zero) {
      setState(() {
        _bannerColor = AppColors.solarGold;
        _bannerText =
            'TV ANTI-SPAM COOLDOWN: WAIT ${remaining.inSeconds + 1}S BEFORE RATING AGAIN';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _bannerText = null;
    });

    try {
      final db = ref.read(appDatabaseProvider);
      final deviceId = await ref
          .read(deviceIdServiceProvider)
          .getOrCreateDeviceId();

      await db.insertRating(
        eventId: 'rt-${const Uuid().v4()}',
        deviceId: deviceId,
        projectId: project.id,
        projectTitle: project.title,
        score: _stars,
      );

      cooldown.recordSubmission(CooldownService.ratingScope);
      final syncReport = await ref
          .read(sheetsSyncServiceProvider)
          .syncPending();

      if (!mounted) {
        return;
      }

      setState(() {
        _bannerColor = AppColors.acidLime;
        _bannerText = syncReport.totalSynced > 0
            ? 'RATED ${project.title} ($_stars/5) — SYNCED TO SHEETS'
            : 'RATED ${project.title} ($_stars/5) — SAVED TO LOCAL DB';
      });
    } catch (err) {
      if (!mounted) {
        return;
      }
      setState(() {
        _bannerColor = AppColors.neonMagenta;
        _bannerText = 'RATING ERROR: $err';
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(showcaseProjectsProvider);
    final activeProject = projects[_selectedProjectIndex];
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: MaximalistBackdrop(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go('/feedback'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('FEEDBACK'),
                  ),
                  Text(
                    'PROJECT RATINGS // TV GUARD',
                    style: textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      'SELECT & RATE A SHOWCASE PROJECT',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      alignment: WrapAlignment.center,
                      children: [
                        for (var i = 0; i < projects.length; i++)
                          ChoiceChip(
                            selected: i == _selectedProjectIndex,
                            label: Text(projects[i].title),
                            onSelected: _submitting
                                ? null
                                : (_) => setState(() {
                                    _selectedProjectIndex = i;
                                    _stars = 0;
                                  }),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 620),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(
                          color: AppColors.electricCyan,
                          width: AppSpacing.borderThick,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.hyperCoral,
                            offset: Offset(
                              AppSpacing.xs + 2,
                              AppSpacing.xs + 2,
                            ),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            activeProject.track,
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.acidLime,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            activeProject.title,
                            textAlign: TextAlign.center,
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var s = 1; s <= 5; s++)
                                IconButton(
                                      iconSize: 44,
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
                                      end: 1.15,
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      curve: Curves.easeOutBack,
                                    ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
                            onPressed: (!_submitting && _stars > 0)
                                ? () => unawaited(_submitRating(activeProject))
                                : null,
                            child: Text(
                              _submitting ? 'SAVING...' : 'SUBMIT RATING',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_bannerText != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          border: Border.all(
                            color: _bannerColor,
                            width: AppSpacing.borderThin,
                          ),
                        ),
                        child: Text(
                          _bannerText!,
                          textAlign: TextAlign.center,
                          style: textTheme.labelLarge?.copyWith(
                            color: _bannerColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const LiveTickerBar(),
          ],
        ),
      ),
    );
  }
}
