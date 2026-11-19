import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/attract_overlay.dart';
import '../widgets/cooldown_screen.dart';
import '../widgets/kiosk_scaffold.dart';
import '../models/emoji_choice.dart';
import '../controllers/feedback_controller.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/rate_projects_prompt.dart';
import '../widgets/thank_you_card.dart';

/// The complete visitor feedback flow — PROJECT_PROCESS.md §10.6, I24.
///
/// Watches the `FeedbackController` state machine and renders one view per
/// state: picker (idle/selecting/submitting) → thank-you (success) →
/// rating prompt (after a short beat) → cooldown/error slots. The prompt's
/// Yes navigates to `/rating` (a placeholder until I29); Skip resets the
/// controller back to idle.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({
    super.key,
    this.thankYouDelay = const Duration(seconds: 2),
  });

  /// How long the thank-you is held before the rating prompt appears.
  /// Injectable so the E2E test advances it instantly.
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

    // Leaving success cancels the beat: no stale prompt on the next visit.
    _promptTimer?.cancel();
    _promptTimer = null;
    if (_showPrompt) {
      setState(() => _showPrompt = false);
    }
  }

  Future<void> _select(EmojiChoice choice) =>
      ref.read(feedbackControllerProvider.notifier).select(choice);

  void _reset() => ref.read(feedbackControllerProvider.notifier).reset();

  @override
  Widget build(BuildContext context) {
    // Riverpod 3 requires listeners to be registered during build.
    ref.listen(feedbackControllerProvider, (previous, next) => _onState(next));
    final state = ref.watch(feedbackControllerProvider);
    return AttractOverlay(child: KioskScaffold(child: _body(state)));
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

    return switch (state) {
      FeedbackIdle() || FeedbackSelecting() || FeedbackSubmitting() => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'How was your visit?',
                  textAlign: TextAlign.center,
                  style: AppTypography.headline.copyWith(
                    color: AppColors.inkPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                EmojiPicker(
                  onSelected: (choice) => unawaited(_select(choice)),
                  autofocusFirst: true,
                ),
              ],
            ),
          ),
        ),
      FeedbackSuccess() => const Center(child: ThankYouCard()),
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
