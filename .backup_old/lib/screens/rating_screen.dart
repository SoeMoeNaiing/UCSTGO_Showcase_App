import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/rating_controller.dart';
import '../models/project.dart';
import '../providers.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/attract_overlay.dart';
import '../widgets/cooldown_screen.dart';
import '../widgets/kiosk_scaffold.dart';
import '../widgets/project_card.dart';
import '../widgets/project_carousel.dart';
import '../widgets/rating_widget.dart';

/// Cyber-Brutalist rating flow preserving [RatingScreen.submitKey],
/// [RatingScreen.confirmationKey], [RatingScreen.statusKey], and controller wiring.
class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({super.key});

  static const submitKey = Key('rating_submit');
  static const confirmationKey = Key('rating_confirmation');
  static const statusKey = Key('rating_status');

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  Project? _selected;
  int _score = 0;

  void _select(Project project) {
    setState(() {
      _selected = project;
      _score = 0;
    });
  }

  void _scoreChanged(int score) => setState(() => _score = score);

  void _submit() {
    final project = _selected;
    if (project == null || _score == 0) {
      return;
    }
    unawaited(
      ref
          .read(ratingControllerProvider.notifier)
          .submit(projectId: project.id, score: _score),
    );
  }

  void _done() {
    ref.read(ratingControllerProvider.notifier).reset();
    setState(() {
      _selected = null;
      _score = 0;
    });
  }

  String _stageKey(RatingState state) {
    return switch (state) {
      RatingSuccess() => 'rating-success',
      RatingSubmitting() => 'rating-submitting',
      RatingCooldown() => 'rating-cooldown',
      RatingError() => 'rating-error',
      RatingIdle() => _selected == null ? 'rating-carousel' : 'rating-stars',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ratingControllerProvider);

    return AttractOverlay(
      child: KioskScaffold(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TextButton(
                  onPressed: () => context.go('/feedback'),
                  child: const Text('← Back'),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_stageKey(state)),
                    child: _body(state),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(RatingState state) {
    return switch (state) {
      RatingSuccess() => _confirmation(),
      RatingSubmitting() => _status('Saving your rating…'),
      RatingCooldown() => KeyedSubtree(
        key: RatingScreen.statusKey,
        child: CooldownScreen(
          remaining: ref.watch(ratingCooldownRemainingProvider),
          onExpiry: _done,
          message: state.message,
        ),
      ),
      RatingError() => KeyedSubtree(
        key: RatingScreen.statusKey,
        child: _statusCopy(state.message),
      ),
      RatingIdle() => _selected == null ? _carousel() : _stars(),
    };
  }

  Widget _carousel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'RATE OUR PROJECTS',
            textAlign: TextAlign.center,
            style: AppTypography.headline.copyWith(color: AppColors.inkPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'SWIPE OR USE ← →, THEN TAP A PROJECT',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.accentSky),
          ),
          const SizedBox(height: AppSpacing.xl),
          ProjectCarousel(
            projects: ref.watch(projectFixturesProvider),
            onSelect: _select,
          ),
        ],
      ),
    );
  }

  Widget _stars() {
    final project = _selected!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            project.title,
            textAlign: TextAlign.center,
            style: AppTypography.headline.copyWith(color: AppColors.inkPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'How would you rate it?',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.inkSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          IgnorePointer(
            child: ProjectCard(project: project, onSelect: (_) {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          RatingWidget(onChanged: _scoreChanged, autofocusFirst: true),
          const SizedBox(height: AppSpacing.xl),
          KeyedSubtree(
            key: RatingScreen.submitKey,
            child: FilledButton(
              onPressed: _score > 0 ? _submit : null,
              child: const Text('Submit rating'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmation() {
    final project = _selected;
    return KeyedSubtree(
      key: RatingScreen.confirmationKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rating saved!',
            style: AppTypography.headline.copyWith(color: AppColors.inkPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            project == null
                ? 'Thanks for your feedback!'
                : 'You rated ${project.title} $_score stars.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.inkSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: _done, child: const Text('Done')),
        ],
      ),
    );
  }

  Widget _status(String message) =>
      KeyedSubtree(key: RatingScreen.statusKey, child: _statusCopy(message));

  Widget _statusCopy(String message) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.body.copyWith(color: AppColors.inkPrimary),
      ),
      const SizedBox(height: AppSpacing.xl),
      FilledButton(onPressed: _done, child: const Text('Done')),
    ],
  );
}
