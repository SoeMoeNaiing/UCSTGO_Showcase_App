import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/attract_overlay.dart';
import '../../../../core/widgets/cooldown_screen.dart';
import '../../../../core/widgets/kiosk_scaffold.dart';
import '../../../rating/presentation/controllers/rating_controller.dart';
import '../../../rating/presentation/widgets/rating_widget.dart';
import '../../../showcase/domain/entities/project.dart';
import '../../../showcase/presentation/widgets/project_card.dart';
import '../../../showcase/presentation/widgets/project_carousel.dart';

/// Full rating flow — carousel → project → stars → submit → confirmation
/// (§10.7, I29). Local pick/score stay here; persistence goes through the
/// tested `RatingController` → `SubmitRating` → local-first queue.
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
      ref.read(ratingControllerProvider.notifier).submit(
            projectId: project.id,
            score: _score,
          ),
    );
  }

  void _done() {
    ref.read(ratingControllerProvider.notifier).reset();
    setState(() {
      _selected = null;
      _score = 0;
    });
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
            child: TextButton(
              onPressed: () => context.go('/feedback'),
              child: const Text('← Back'),
            ),
          ),
          Expanded(child: Center(child: _body(state))),
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
            'Rate our projects?',
            textAlign: TextAlign.center,
            style: AppTypography.headline.copyWith(
              color: AppColors.inkPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Swipe or use ← →, then tap a project.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
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
            style: AppTypography.headline.copyWith(
              color: AppColors.inkPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'How would you rate it?',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.inkSecondary,
            ),
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
            style: AppTypography.headline.copyWith(
              color: AppColors.inkPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            project == null
                ? 'Thanks for your feedback!'
                : 'You rated ${project.title} $_score stars.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: _done, child: const Text('Done')),
        ],
      ),
    );
  }

  Widget _status(String message) => KeyedSubtree(
        key: RatingScreen.statusKey,
        child: _statusCopy(message),
      );

  Widget _statusCopy(String message) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.inkPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: _done, child: const Text('Done')),
        ],
      );
}
