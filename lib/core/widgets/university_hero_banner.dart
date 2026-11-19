import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/showcase_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Maximalist University photo showcase banner using a network image URL
/// with a graceful fallback card when offline or unreachable.
class UniversityHeroBanner extends StatelessWidget {
  const UniversityHeroBanner({
    super.key,
    this.imageUrl = ShowcaseConfig.universityImageUrl,
    this.institutionName = ShowcaseConfig.institutionName,
    this.tagline = ShowcaseConfig.showcaseTagline,
  });

  final String imageUrl;
  final String institutionName;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Container(
          constraints: const BoxConstraints(maxWidth: 820),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.electricCyan,
              width: AppSpacing.borderThick,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.hyperCoral,
                offset: Offset(AppSpacing.sm, AppSpacing.sm),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: AppColors.surfaceElevated,
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.solarGold,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        institutionName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.labelLarge,
                      ),
                    ),
                    Text(
                      'SHOWCASE // LIVE',
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        color: AppColors.acidLime,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 170,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) {
                          return child;
                        }
                        return const ColoredBox(
                          color: AppColors.surfaceDark,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.electricCyan,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => _CampusFallbackView(
                        institutionName: institutionName,
                        tagline: tagline,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        color: AppColors.voidBlack.withValues(alpha: 0.78),
                        child: Text(
                          tagline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textTheme.labelLarge?.copyWith(
                            color: AppColors.solarGold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: const Duration(milliseconds: 3400),
          color: AppColors.electricCyan.withValues(alpha: 0.14),
        );
  }
}

class _CampusFallbackView extends StatelessWidget {
  const _CampusFallbackView({
    required this.institutionName,
    required this.tagline,
  });

  final String institutionName;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceElevated,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            institutionName,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.titleLarge?.copyWith(
              color: AppColors.electricCyan,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            tagline,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
