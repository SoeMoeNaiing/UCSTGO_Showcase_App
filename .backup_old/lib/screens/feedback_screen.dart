import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/feedback_controller.dart';
import '../models/emoji_choice.dart';
import '../providers.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/attract_overlay.dart';
import '../widgets/cooldown_screen.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/kiosk_scaffold.dart';
import '../widgets/rate_projects_prompt.dart';
import '../widgets/sketch_animation.dart';
import '../widgets/thank_you_card.dart';
import '../widgets/university_banner.dart';

/// Cyber-Brutalist Maximalist visitor feedback flow.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({
    super.key,
    this.thankYouDelay = const Duration(seconds: 2),
  });

  final Duration thankYouDelay;

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  bool _showPrompt = false;
  Timer? _promptTimer;

  @override
  void dispose() {
    _promptTimer?.cancel();
    super.dispose();
  }

  void _onState(FeedbackState next) {
    if (next is FeedbackSuccess) {
      _promptTimer?.cancel();
      _promptTimer = Timer(widget.thankYouDelay, () {
        if (mounted) {
          setState(() => _showPrompt = true);
        }
      });
      return;
    }

    _promptTimer?.cancel();
    _promptTimer = null;
    if (_showPrompt) {
      setState(() => _showPrompt = false);
    }
  }

  Future<void> _select(EmojiChoice choice) =>
      ref.read(feedbackControllerProvider.notifier).select(choice);

  void _reset() => ref.read(feedbackControllerProvider.notifier).reset();

  String _stageKey(FeedbackState state) {
    if (_showPrompt && state is FeedbackSuccess) {
      return 'prompt';
    }
    return switch (state) {
      FeedbackIdle() => 'picker-idle',
      FeedbackSelecting() => 'picker-selecting',
      FeedbackSubmitting() => 'picker-submitting',
      FeedbackSuccess() => 'thank-you',
      FeedbackCooldown() => 'cooldown',
      FeedbackError() => 'error',
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(feedbackControllerProvider, (previous, next) => _onState(next));
    final state = ref.watch(feedbackControllerProvider);

    return AttractOverlay(
      child: KioskScaffold(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final scale = Tween<double>(
              begin: 0.97,
              end: 1.0,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: scale, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_stageKey(state)),
            child: _body(state),
          ),
        ),
      ),
    );
  }

  Widget _body(FeedbackState state) {
    if (_showPrompt && state is FeedbackSuccess) {
      return Center(
        child: RateProjectsPrompt(
          onYes: () => context.go('/rating'),
          onSkip: _reset,
        ),
      );
    }

    final isBusy = state is FeedbackSelecting || state is FeedbackSubmitting;

    return switch (state) {
      FeedbackIdle() || FeedbackSelecting() || FeedbackSubmitting() => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const UniversityBanner(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'HOW WAS YOUR VISIT?',
                textAlign: TextAlign.center,
                style: AppTypography.headline.copyWith(
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              EmojiPicker(
                onSelected: (choice) => unawaited(_select(choice)),
                autofocusFirst: true,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: isBusy
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xl),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: AppSpacing.lg,
                              height: AppSpacing.lg,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.accentWarm,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'SAVING YOUR CHOICE…',
                              style: AppTypography.body.copyWith(
                                color: AppColors.accentSky,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
      FeedbackSuccess() => const Center(
        child: ThankYouCard(animationBackend: FallbackSketchAnimationBackend()),
      ),
      FeedbackCooldown() => CooldownScreen(
        remaining: ref.watch(feedbackCooldownRemainingProvider),
        onExpiry: _reset,
        message: state.message,
      ),
      FeedbackError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.inkPrimary),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: _reset, child: const Text('Try again')),
          ],
        ),
      ),
    };
  }
}
