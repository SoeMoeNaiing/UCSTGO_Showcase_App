import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Displays a maximalist cyber-styled dialog with elastic pop-in and
/// crisp pop-out scale + fade transitions.
Future<T?> showMaximalistPopDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color borderColor = AppColors.electricCyan,
  Color shadowColor = AppColors.hyperCoral,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: AppColors.voidBlack.withValues(alpha: 0.82),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: borderColor,
                      width: AppSpacing.borderThick,
                    ),
                    boxShadow: [
                      BoxShadow(color: shadowColor, offset: const Offset(6, 6)),
                    ],
                  ),
                  child: builder(dialogContext),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curve = animation.status == AnimationStatus.reverse
          ? Curves.easeInBack
          : Curves.easeOutBack;
      final curved = CurvedAnimation(parent: animation, curve: curve);
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
