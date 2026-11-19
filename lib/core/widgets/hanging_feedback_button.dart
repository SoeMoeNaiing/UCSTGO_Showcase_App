import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Continuously looping, hanging/floating FEEDBACK pill button anchored
/// on mobile screens so visitors can jump to the Emotions page anytime.
class HangingFeedbackButton extends StatelessWidget {
  const HangingFeedbackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.hyperCoral,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.solarGold,
                width: AppSpacing.borderThick,
              ),
              boxShadow: const [
                BoxShadow(color: AppColors.electricCyan, offset: Offset(4, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mood_rounded,
                  color: AppColors.voidBlack,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'FEEDBACK',
                  style: AppTypography.textTheme.labelLarge?.copyWith(
                    color: AppColors.voidBlack,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(
          begin: -6,
          end: 4,
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeInOutSine,
        )
        .scaleXY(
          begin: 0.98,
          end: 1.04,
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeInOut,
        );
  }
}
