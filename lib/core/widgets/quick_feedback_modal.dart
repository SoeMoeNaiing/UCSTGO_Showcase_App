import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ucstgo_showcase_flutter_app/models/kiosk_emotion.dart';

class QuickFeedbackModal extends ConsumerStatefulWidget {
  const QuickFeedbackModal({
    super.key,
    required this.onSubmitFeedback,
    required this.onPauseIdle,
    required this.onResumeIdle,
    required this.onPingIdle,
    required this.onTriggerBackgroundSync,
    required this.onShowToast,
    this.cooldownRemainingSeconds = 0,
  });

  final Future<bool> Function({
    required KioskEmotion emotion,
    required String note,
  }) onSubmitFeedback;

  final VoidCallback onPauseIdle;
  final VoidCallback onResumeIdle;
  final VoidCallback onPingIdle;
  final Future<void> Function() onTriggerBackgroundSync;
  final void Function(String message, {required bool isSuccess}) onShowToast;
  final int cooldownRemainingSeconds;

  static Future<void> show(
    BuildContext context, {
    required Future<bool> Function({
      required KioskEmotion emotion,
      required String note,
    }) onSubmitFeedback,
    required VoidCallback onPauseIdle,
    required VoidCallback onResumeIdle,
    required VoidCallback onPingIdle,
    required Future<void> Function() onTriggerBackgroundSync,
    required void Function(String message, {required bool isSuccess}) onShowToast,
    int cooldownRemainingSeconds = 0,
  }) {
    onPauseIdle();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xB3070A12),
      builder: (_) => QuickFeedbackModal(
        onSubmitFeedback: onSubmitFeedback,
        onPauseIdle: onPauseIdle,
        onResumeIdle: onResumeIdle,
        onPingIdle: onPingIdle,
        onTriggerBackgroundSync: onTriggerBackgroundSync,
        onShowToast: onShowToast,
        cooldownRemainingSeconds: cooldownRemainingSeconds,
      ),
    ).whenComplete(onResumeIdle);
  }

  @override
  ConsumerState<QuickFeedbackModal> createState() => _QuickFeedbackModalState();
}

class _QuickFeedbackModalState extends ConsumerState<QuickFeedbackModal>
    with SingleTickerProviderStateMixin {
  KioskEmotion? _selectedEmotion;
  final Set<String> _selectedTags = <String>{};
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;
  String? _inlineError;

  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    widget.onPingIdle();
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
      _inlineError = null;
    });
  }

  String _composeNote() {
    final custom = _noteController.text.trim();
    final tags = _selectedTags.join(' • ');
    if (tags.isEmpty) return custom;
    if (custom.isEmpty) return tags;
    return '$tags — $custom';
  }

  Future<void> _closeWithTransition({VoidCallback? afterDismiss}) async {
    if (!mounted) return;
    await _animController.reverse();
    if (!mounted) return;
    Navigator.of(context).pop();
    if (afterDismiss != null) {
      afterDismiss();
    }
  }

  Future<void> _handleSubmit({required bool goToRatingAfter}) async {
    widget.onPingIdle();
    if (_isSubmitting) return;

    if (widget.cooldownRemainingSeconds > 0) {
      setState(() {
        _inlineError =
            'COOLDOWN ACTIVE: WAIT ${widget.cooldownRemainingSeconds}S';
      });
      return;
    }

    final emotion = _selectedEmotion;
    if (emotion == null) {
      setState(() {
        _inlineError = 'SELECT A REACTION BEFORE SUBMITTING';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    final saved = await widget.onSubmitFeedback(
      emotion: emotion,
      note: _composeNote(),
    );

    if (!mounted) return;

    if (!saved) {
      setState(() {
        _isSubmitting = false;
        _inlineError = 'COULD NOT SAVE FEEDBACK — TRY AGAIN';
      });
      return;
    }

    unawaited(widget.onTriggerBackgroundSync());

    if (goToRatingAfter) {
      await _closeWithTransition(
        afterDismiss: () {
          if (!mounted) return;
          widget.onShowToast(
            'FEEDBACK SAVED — PICK A PROJECT TO RATE',
            isSuccess: true,
          );
          context.go('/rating');
        },
      );
    } else {
      await _closeWithTransition(
        afterDismiss: () {
          widget.onShowToast(
            'FEEDBACK RECORDED (${emotion.label})',
            isSuccess: true,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = _selectedEmotion?.accent ?? const Color(0xFF00E5FF);

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(_scaleAnim),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xE60D1322),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: activeAccent.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'QUICK SHOWCASE PULSE',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                                color: activeAccent,
                              ),
                            ),
                            IconButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _closeWithTransition(),
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: Color(0xB3F5F7FF),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'How does the showcase feel right now?',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF5F7FF),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: KioskEmotion.values.map((emotion) {
                            final selected = _selectedEmotion == emotion;
                            return _EmotionChip(
                              emotion: emotion,
                              selected: selected,
                              onTap: () {
                                widget.onPingIdle();
                                setState(() {
                                  _selectedEmotion = emotion;
                                  _inlineError = null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'OPTIONAL QUICK TAGS',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: const Color(0x73F5F7FF),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: kQuickFeedbackTags.map((tag) {
                            final isTagged = _selectedTags.contains(tag);
                            return InkWell(
                              onTap: () => _toggleTag(tag),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isTagged
                                      ? const Color(0x2600E5FF)
                                      : const Color(0x0AFFFFFF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isTagged
                                        ? const Color(0xFF00E5FF)
                                        : const Color(0x24FFFFFF),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isTagged
                                        ? const Color(0xFF00E5FF)
                                        : const Color(0xB3F5F7FF),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          onChanged: (_) => widget.onPingIdle(),
                          maxLines: 1,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFFF5F7FF),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Optional short note...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0x66F5F7FF),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF070A12),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0x24FFFFFF),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: activeAccent,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        if (_inlineError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _inlineError!,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFD60A),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _handleSubmit(
                                            goToRatingAfter: false,
                                          ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFF070A12),
                                    side: BorderSide(
                                      color: activeAccent.withValues(alpha: 0.6),
                                      width: 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'SUBMIT FEEDBACK',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: const Color(0xFFF5F7FF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _handleSubmit(
                                            goToRatingAfter: true,
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00E5FF),
                                    foregroundColor: const Color(0xFF070A12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'SUBMIT & RATE PROJECT',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmotionChip extends StatelessWidget {
  const _EmotionChip({
    required this.emotion,
    required this.selected,
    required this.onTap,
  });

  final KioskEmotion emotion;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? emotion.accent : const Color(0x24FFFFFF);
    final fillColor = selected
        ? emotion.accent.withValues(alpha: 0.16)
        : const Color(0xFF070A12);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedScale(
        scale: selected ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Image.network(
                  emotion.assetUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: emotion.accent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      emotion.label.substring(0, 1),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: emotion.accent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                emotion.label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xFFF5F7FF)
                      : const Color(0xB3F5F7FF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
