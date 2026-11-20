import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/showcase_providers.dart';
import '../../core/services/cooldown_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class _ColorfulReaction {
  const _ColorfulReaction({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.svg,
  });

  final String id;
  final String label;
  final String subtitle;
  final Color accent;
  final String svg;
}

const List<_ColorfulReaction> _showReactions = [
  _ColorfulReaction(
    id: 'loved_show',
    label: 'LOVED IT',
    subtitle: 'Amazing student builds',
    accent: Color(0xFFFF4D6D),
    svg: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="21" fill="#FFD43B"/>
  <circle cx="24" cy="24" r="21" fill="none" stroke="#F59F00" stroke-width="2"/>
  <path d="M16.5 19.5c-1.7-2.1-5-1.9-6.3.4-1.2 2.1-.4 4.8 6.3 8.6 6.7-3.8 7.5-6.5 6.3-8.6-1.3-2.3-4.6-2.5-6.3-.4z" fill="#FA5252"/>
  <path d="M31.5 19.5c-1.7-2.1-5-1.9-6.3.4-1.2 2.1-.4 4.8 6.3 8.6 6.7-3.8 7.5-6.5 6.3-8.6-1.3-2.3-4.6-2.5-6.3-.4z" fill="#FA5252"/>
  <path d="M15 31c2.2 4.2 15.8 4.2 18 0" fill="none" stroke="#5C3C00" stroke-width="2.8" stroke-linecap="round"/>
</svg>
''',
  ),
  _ColorfulReaction(
    id: 'mind_blown',
    label: 'MIND BLOWN',
    subtitle: 'Creative tech & demos',
    accent: Color(0xFFFFB703),
    svg: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="21" fill="#FFD43B"/>
  <circle cx="24" cy="24" r="21" fill="none" stroke="#F59F00" stroke-width="2"/>
  <path d="M13 15.5c1.8-1.5 4.2-1.5 6 0M29 15.5c1.8-1.5 4.2-1.5 6 0" fill="none" stroke="#5C3C00" stroke-width="2.4" stroke-linecap="round"/>
  <circle cx="16.5" cy="21" r="2.6" fill="#2B1D00"/>
  <circle cx="31.5" cy="21" r="2.6" fill="#2B1D00"/>
  <ellipse cx="24" cy="33" rx="4.8" ry="6.2" fill="#4A2511"/>
  <path d="M20.5 35.5c1.8-1.6 5.2-1.6 7 0" fill="none" stroke="#FF6B6B" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''',
  ),
  _ColorfulReaction(
    id: 'super_fun',
    label: 'GREAT VIBE',
    subtitle: 'Enjoyed visiting booths',
    accent: Color(0xFF38BDF8),
    svg: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="21" fill="#FFD43B"/>
  <circle cx="24" cy="24" r="21" fill="none" stroke="#F59F00" stroke-width="2"/>
  <path d="M13 21c1.5-2.6 4.5-2.6 6 0M29 21c1.5-2.6 4.5-2.6 6 0" fill="none" stroke="#2B1D00" stroke-width="2.8" stroke-linecap="round"/>
  <path d="M14 27.5h20c0 6.5-4.5 11-10 11s-10-4.5-10-11z" fill="#4A2511"/>
  <path d="M17.5 34.5c2.2-2.2 10.8-2.2 13 0-1.8 2.5-4.2 3.8-6.5 3.8s-4.7-1.3-6.5-3.8z" fill="#FF6B6B"/>
</svg>
''',
  ),
  _ColorfulReaction(
    id: 'inspired',
    label: 'INSPIRED',
    subtitle: 'Learned something new',
    accent: Color(0xFFA3E635),
    svg: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="21" fill="#FFD43B"/>
  <circle cx="24" cy="24" r="21" fill="none" stroke="#F59F00" stroke-width="2"/>
  <path d="M16.5 16l1.3 2.7 3 .4-2.2 2.1.5 3-2.6-1.4-2.6 1.4.5-3-2.2-2.1 3-.4z" fill="#FF922B"/>
  <path d="M31.5 16l1.3 2.7 3 .4-2.2 2.1.5 3-2.6-1.4-2.6 1.4.5-3-2.2-2.1 3-.4z" fill="#FF922B"/>
  <path d="M15.5 30c2.5 4.2 14.5 4.2 17 0" fill="none" stroke="#5C3C00" stroke-width="2.8" stroke-linecap="round"/>
</svg>
''',
  ),
  _ColorfulReaction(
    id: 'curious',
    label: 'INTERESTING',
    subtitle: 'Want to see more details',
    accent: Color(0xFFC084FC),
    svg: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="21" fill="#FFD43B"/>
  <circle cx="24" cy="24" r="21" fill="none" stroke="#F59F00" stroke-width="2"/>
  <circle cx="16.5" cy="20.5" r="2.4" fill="#2B1D00"/>
  <circle cx="31.5" cy="19.5" r="2.4" fill="#2B1D00"/>
  <path d="M28 14.5c2-1.2 4.5-1.2 6.5.3" fill="none" stroke="#5C3C00" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M17 31.5c2.5-1.2 10.5-1.2 13.5.4" fill="none" stroke="#5C3C00" stroke-width="2.6" stroke-linecap="round"/>
</svg>
''',
  ),
  _ColorfulReaction(
    id: 'crowded_or_rough',
    label: 'COULD IMPROVE',
    subtitle: 'Demo or booth hiccups',
    accent: Color(0xFFFB7185),
    svg: '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="21" fill="#FFD43B"/>
  <circle cx="24" cy="24" r="21" fill="none" stroke="#F59F00" stroke-width="2"/>
  <circle cx="16.5" cy="21" r="2.4" fill="#2B1D00"/>
  <circle cx="31.5" cy="21" r="2.4" fill="#2B1D00"/>
  <path d="M13 17l5.5 1.8M35 17l-5.5 1.8" fill="none" stroke="#5C3C00" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M16.5 33.5c2.2-2.6 12.8-2.6 15 0" fill="none" stroke="#5C3C00" stroke-width="2.6" stroke-linecap="round"/>
</svg>
''',
  ),
];

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  bool _showRateChoice = false;
  String? _selectedReaction;
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;

  String? _statusMessage;
  Color _statusColor = AppColors.acidLime;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final reaction = _selectedReaction;
    if (_submitting || reaction == null) {
      return;
    }

    final cooldown = ref.read(cooldownServiceProvider);
    final remaining = cooldown.remaining(CooldownService.feedbackScope);
    if (remaining > Duration.zero) {
      setState(() {
        _statusColor = AppColors.solarGold;
        _statusMessage =
            'WAIT ${remaining.inSeconds + 1}S BEFORE SENDING AGAIN';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _statusMessage = null;
    });

    try {
      final db = ref.read(appDatabaseProvider);
      final deviceId = await ref
          .read(deviceIdServiceProvider)
          .getOrCreateDeviceId();

      await db.insertFeedback(
        eventId: 'fb-${const Uuid().v4()}',
        deviceId: deviceId,
        sentiment: reaction,
        note: _noteController.text.trim(),
      );

      cooldown.recordSubmission(CooldownService.feedbackScope);
      _showRateChoice = true;
      await ref.read(sheetsSyncServiceProvider).syncPending();

      if (!mounted) {
        return;
      }

      setState(() {
        _statusColor = AppColors.acidLime;
        _statusMessage = 'THANKS FOR VISITING! OPENING PROJECT RATINGS...';
      });

      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) {
        context.go('/rating');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF070A12),
      body: SafeArea(
        child: ListView(
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
                Text(
                  'VISITOR CHECK-IN // PROJECT SHOW',
                  style: textTheme.labelLarge?.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.electricCyan,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'How is your visit to the Project Show?',
              style: textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontSize: 23,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'React to the student exhibition & booths, then rate individual projects.',
              style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.lg),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _showReactions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.28,
              ),
              itemBuilder: (context, index) {
                final item = _showReactions[index];
                final selected = _selectedReaction == item.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedReaction = item.id),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: selected
                              ? item.accent.withValues(alpha: 0.16)
                              : const Color(0xFF101726).withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected
                                ? item.accent
                                : Colors.white.withValues(alpha: 0.14),
                            width: selected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.string(item.svg, width: 42, height: 42)
                                .animate(target: selected ? 1 : 0)
                                .scaleXY(
                                  begin: 1.0,
                                  end: 1.18,
                                  duration: 200.ms,
                                  curve: Curves.easeOutBack,
                                ),
                            const SizedBox(height: 8),
                            Text(
                              item.label,
                              style: textTheme.labelLarge?.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: selected ? item.accent : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: TextField(
                  controller: _noteController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Share a quick note about the show or booths...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF101726).withValues(alpha: 0.78),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.electricCyan,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.electricCyan,
                foregroundColor: AppColors.voidBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: (!_submitting && _selectedReaction != null)
                  ? () => unawaited(_submitFeedback())
                  : null,
              child: Text(
                _submitting ? 'SAVING...' : 'SUBMIT FEEDBACK TO RATE PROJECTS',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: textTheme.labelLarge?.copyWith(
                  fontFamily: 'monospace',
                  color: _statusColor,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFF101726).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.electricCyan.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OPTIONAL // RATE STUDENT PROJECTS?',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.electricCyan,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Rate projects now, or skip rating and return to the landing page.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Text(
                            'SKIP & HOME',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => context.go('/rating'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.electricCyan,
                            foregroundColor: AppColors.voidBlack,
                          ),
                          child: const Text(
                            'RATE PROJECTS',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_showRateChoice) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFF101726).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.electricCyan.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FEEDBACK SUBMITTED // RATE PROJECTS?',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.electricCyan,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Would you like to rate student projects now, or skip and return to the landing page?',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go('/'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Text(
                              'SKIP & HOME',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => context.go('/rating'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.electricCyan,
                              foregroundColor: AppColors.voidBlack,
                            ),
                            child: const Text(
                              'RATE PROJECTS',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
