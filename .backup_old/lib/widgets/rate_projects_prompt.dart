import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import './sketch_focus_frame.dart';

/// Cyber-Brutalist prompt card after feedback submission.
class RateProjectsPrompt extends StatelessWidget {
  const RateProjectsPrompt({
    super.key,
    required this.onYes,
    required this.onSkip,
    this.autofocusYes = false,
  });

  final VoidCallback onYes;
  final VoidCallback onSkip;
  final bool autofocusYes;

  static Key focusFrameKey(String label) =>
      ValueKey('rate-prompt-focus-${label.toLowerCase()}');

  @override
  Widget build(BuildContext context) {
    return Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.paperWhite,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            border: Border.all(color: AppColors.accentSky, width: 2.5),
            boxShadow: const [
              BoxShadow(color: AppColors.accentWarm, offset: Offset(8, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RATE OUR PROJECTS?',
                textAlign: TextAlign.center,
                style: AppTypography.headline.copyWith(
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PromptButton(
                    label: 'Yes',
                    onPressed: onYes,
                    primary: true,
                    autofocus: autofocusYes,
                    focusKey: focusFrameKey('yes'),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _PromptButton(
                    label: 'Skip',
                    onPressed: onSkip,
                    focusKey: focusFrameKey('skip'),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 280.ms)
        .scaleXY(
          begin: 0.94,
          end: 1.0,
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
  }
}

class _PromptButton extends StatefulWidget {
  const _PromptButton({
    required this.label,
    required this.onPressed,
    required this.focusKey,
    this.primary = false,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback onPressed;
  final Key focusKey;
  final bool primary;
  final bool autofocus;

  @override
  State<_PromptButton> createState() => _PromptButtonState();
}

class _PromptButtonState extends State<_PromptButton>
    with SingleTickerProviderStateMixin {
  final FocusNode _node = FocusNode();
  late final AnimationController _frame = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocusChange);
    _frame.dispose();
    _node.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) {
      return;
    }
    if (_node.hasFocus) {
      _frame.forward(from: 0);
      setState(() => _focused = true);
    } else {
      _frame.value = 0;
      setState(() => _focused = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.primary
        ? AppColors.accentWarm
        : AppColors.paperBackground;
    final foreground = widget.primary
        ? AppColors.paperBackground
        : AppColors.inkPrimary;

    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onPressed,
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedScale(
              scale: _focused ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutBack,
              child: InkWell(
                focusNode: _node,
                autofocus: widget.autofocus,
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(AppSpacing.xs),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                    border: Border.all(
                      color: widget.primary
                          ? AppColors.idleGlow
                          : AppColors.accentSky,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.paperShadow,
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.label,
                    style: AppTypography.body.copyWith(color: foreground),
                  ),
                ),
              ),
            ),
            if (_focused)
              Positioned(
                left: -AppSpacing.xs,
                top: -AppSpacing.xs,
                right: -AppSpacing.xs,
                bottom: -AppSpacing.xs,
                child: IgnorePointer(
                  child: CustomPaint(
                    key: widget.focusKey,
                    painter: SketchFocusFramePainter(
                      progress: _frame,
                      color: AppColors.idleGlow,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
