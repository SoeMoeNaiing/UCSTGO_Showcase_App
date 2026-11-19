import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/feedback/presentation/screens/feedback_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Kiosk routes — `/feedback` is the entry point (§10.6, I24).
///
/// `/rating` is a placeholder until the real `RatingScreen` lands at I29;
/// registering it now keeps the Yes action a real navigation rather than
/// a silent no-op.
final appRouter = GoRouter(
  initialLocation: '/feedback',
  routes: [
    GoRoute(
      path: '/feedback',
      builder: (context, state) => const FeedbackScreen(),
    ),
    GoRoute(
      path: '/rating',
      builder: (context, state) => const _RatingPlaceholder(),
    ),
  ],
);

class _RatingPlaceholder extends StatelessWidget {
  const _RatingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rating arrives at I29',
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () => context.go('/feedback'),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
