import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Cyber-Brutalist Maximalist banner featuring a dedicated University photo
/// slot backed by `Image.network` with a safe fallback when offline.
class UniversityBanner extends StatelessWidget {
  const UniversityBanner({
    super.key,
    this.imageUrl = 'https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=1200&q=80',
    this.institutionName = 'UCSTGO // CAMPUS SHOWCASE',
    this.subtitle = 'SYSTEMS • AI • INTERACTIVE KIOSK',
  });

  final String imageUrl;
  final String institutionName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
          constraints: const BoxConstraints(maxWidth: 680),
          decoration: BoxDecoration(
            color: AppColors.paperWhite,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            border: Border.all(color: AppColors.accentSky, width: 2.5),
            boxShadow: const [
              BoxShadow(color: AppColors.accentWarm, offset: Offset(6, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                color: AppColors.accentSky,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        institutionName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.paperBackground,
                        ),
                      ),
                    ),
                    Text(
                      'LIVE // 2026',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperBackground,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 156,
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
                        return Container(
                          color: AppColors.paperBackground,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: AppSpacing.xl,
                            height: AppSpacing.xl,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.accentSky,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          _FallbackCampusPlate(
                            institutionName: institutionName,
                            subtitle: subtitle,
                          ),
                    ),
                    Positioned(
                      left: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        color: AppColors.paperBackground.withValues(alpha: 0.9),
                        child: Text(
                          subtitle,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.idleGlow,
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
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(
          duration: const Duration(milliseconds: 3600),
          color: AppColors.accentSky.withValues(alpha: 0.14),
        );
  }
}

class _FallbackCampusPlate extends StatelessWidget {
  const _FallbackCampusPlate({
    required this.institutionName,
    required this.subtitle,
  });

  final String institutionName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.paperBackground,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            institutionName,
            textAlign: TextAlign.center,
            style: AppTypography.headline.copyWith(color: AppColors.accentWarm),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
