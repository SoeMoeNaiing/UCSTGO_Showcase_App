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
import '../../core/theme/app_typography.dart';
import '../../core/widgets/live_ticker_bar.dart';
import '../../core/widgets/maximalist_backdrop.dart';
import '../../core/widgets/pop_modal.dart';

enum VisitorEmotion {
  mindBlown('mind_blown', 'MIND BLOWN', '🤯', AppColors.neonMagenta),
  lovedIt('loved', 'LOVED IT', '🤩', AppColors.acidLime),
  inspired('inspired', 'INSPIRED', '🚀', AppColors.electricCyan),
  okay('okay', 'PRETTY GOOD', '🙂', AppColors.solarGold),
  confused('confused', 'CONFUSED', '🤔', AppColors.inkPrimary),
  needsWork('needs_work', 'NEEDS WORK', '🛠️', AppColors.hyperCoral);

  const VisitorEmotion(this.code, this.label, this.emoji, this.accent);

  final String code;
  final String label;
  final String emoji;
  final Color accent;
}

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _onEmotionTap(VisitorEmotion emotion) async {
    if (_saving) {
      return;
    }

    final cooldown = ref.read(cooldownServiceProvider);
    final remaining = cooldown.remaining(CooldownService.feedbackScope);
    if (remaining > Duration.zero) {
      await showMaximalistPopDialog<void>(
        context: context,
        borderColor: AppColors.solarGold,
        shadowColor: AppColors.hyperCoral,
        builder: (dialogContext) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer_outlined,
              size: 46,
              color: AppColors.solarGold,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'ANTI-SPAM COOLDOWN',
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.titleLarge
                  ?.copyWith(color: AppColors.solarGold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please wait ${remaining.inSeconds + 1}s before sending another reaction.',
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('GOT IT'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final db = ref.read(appDatabaseProvider);
      final deviceId = await ref
          .read(deviceIdServiceProvider)
          .getOrCreateDeviceId();

      await db.insertFeedback(
        eventId: 'fb-${const Uuid().v4()}',
        deviceId: deviceId,
        sentiment: emotion.code,
        note: _noteController.text.trim(),
      );

      cooldown.recordSubmission(CooldownService.feedbackScope);
      _noteController.clear();

      final report = await ref.read(sheetsSyncServiceProvider).syncPending();
      if (!mounted) {
        return;
      }

      await showMaximalistPopDialog<void>(
        context: context,
        borderColor: emotion.accent,
        shadowColor: AppColors.electricCyan,
        builder: (dialogContext) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emotion.emoji, style: const TextStyle(fontSize: 54))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.94, end: 1.12, duration: 700.ms),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'THANK YOU!',
              style: Theme.of(dialogContext).textTheme.headlineMedium
                  ?.copyWith(color: emotion.accent),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              report.totalSynced > 0
                  ? 'Reaction "${emotion.label}" synced to Google Sheets!'
                  : 'Reaction "${emotion.label}" saved locally!',
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('STAY HERE'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.go('/');
                  },
                  child: const Text('EXPLORE PROJECTS'),
                ),
              ],
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                children: [
                  TextButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('PROJECTS'),
                  ),
                  const Spacer(),
                  Text('PICK YOUR VIBE', style: textTheme.labelLarge),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Text(
                      'HOW DOES THE SHOWCASE FEEL?',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tap an emotion card to drop instant feedback',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = constraints.maxWidth >= 600 ? 3 : 2;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: VisitorEmotion.values.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                mainAxisSpacing: AppSpacing.md,
                                crossAxisSpacing: AppSpacing.md,
                                childAspectRatio: 1.18,
                              ),
                          itemBuilder: (context, index) {
                            final emotion = VisitorEmotion.values[index];
                            return _EmotionCard(
                              emotion: emotion,
                              index: index,
                              disabled: _saving,
                              onTap: () => unawaited(_onEmotionTap(emotion)),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: TextField(
                        controller: _noteController,
                        enabled: !_saving,
                        maxLength: 140,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceDark,
                          hintText: 'Optional shout-out or suggestion...',
                          hintStyle: AppTypography.textTheme.bodyMedium,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.electricCyan,
                              width: AppSpacing.borderThin,
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _EmotionCard extends StatelessWidget {
  const _EmotionCard({
    required this.emotion,
    required this.index,
    required this.disabled,
    required this.onTap,
  });

  final VisitorEmotion emotion;
  final int index;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: emotion.accent,
                width: AppSpacing.borderThick,
              ),
              boxShadow: [
                BoxShadow(
                  color: emotion.accent.withValues(alpha: 0.35),
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emotion.emoji, style: const TextStyle(fontSize: 38))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(
                      begin: -3,
                      end: 3,
                      delay: (index * 160).ms,
                      duration: const Duration(milliseconds: 1500),
                    ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  emotion.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: emotion.accent),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 60).ms, duration: 260.ms)
        .scaleXY(
          begin: 0.9,
          end: 1.0,
          delay: (index * 60).ms,
          duration: 280.ms,
          curve: Curves.easeOutBack,
        );
  }
}
