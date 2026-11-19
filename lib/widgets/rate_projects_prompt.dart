import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import './sketch_focus_frame.dart';

/// The "Rate our projects?" card shown after a thank-you (§5.1).
///
/// Two focusable actions: **Yes** (→ rating) and **Skip** (→ idle). Render-
/// only — I24 wires the callbacks and chooses when to show it. D-pad and
/// touch share the same focus affordance as the emoji faces.
class RateProjectsPrompt extends StatelessWidget {
  const RateProjectsPrompt({
    super.key,
    required this.onYes,
    required this.onSkip,
    this.autofocusYes = false,
  });

  /// Invoked once when **Yes** is activated.
  final VoidCallback onYes;

  /// Invoked once when **Skip** is activated.
  final VoidCallback onSkip;

  /// Requests focus on **Yes** after the first frame (TV / I24).
  final bool autofocusYes;

  /// Stable key for a button's sketch focus frame.
  static Key focusFrameKey(String label) =>
      ValueKey('rate-prompt-focus-${label.toLowerCase()}');

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.paperWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        side: const BorderSide(color: AppColors.paperShadow, width: 2),
      ),
      child: Padding(
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
      ),
    );
  }
}

/// One prompt action: an `InkWell` (tap + Enter/Space + semantics) with a
/// listener-driven sketch focus frame and a small pop. No bare gestures.
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
    duration: const Duration(milliseconds: 400),
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
    final background =
        widget.primary ? AppColors.accentWarm : AppColors.paperWhite;
    final foreground =
        widget.primary ? AppColors.paperWhite : AppColors.inkPrimary;

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
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: InkWell(
                focusNode: _node,
                autofocus: widget.autofocus,
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    border: Border.all(
                      color:
                          widget.primary ? background : AppColors.inkPrimary,
                      width: 2,
                    ),
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
                      color: AppColors.accentWarm,
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
