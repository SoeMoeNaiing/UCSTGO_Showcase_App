import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/project.dart';

/// A showcase project as a hand-taped polaroid (§5.1, §10.7).
///
/// Selection is a button action: tap, Enter/Space and screen-reader tap all
/// call [onSelect] exactly once with the project. The whole visual is one
/// semantic node with the blurb as its hint.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onSelect,
    this.autofocus = false,
  });

  /// Project shown on the card.
  final Project project;

  /// Fired once when the visitor selects this card.
  final ValueChanged<Project> onSelect;

  /// Requests focus after the first frame (carousel / TV).
  final bool autofocus;

  static const double cardWidth = 220;
  static const double cardHeight = 288;

  void _select() => onSelect(project);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: project.title,
      hint: project.blurb,
      onTap: _select,
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              autofocus: autofocus,
              onTap: _select,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: Container(
                width: cardWidth,
                height: cardHeight,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.paperWhite,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.paperShadow,
                      blurRadius: AppSpacing.lg,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: project.imageAsset == null
                          ? CustomPaint(
                              painter: _PlaceholderArtPainter(
                                ink: AppColors.inkPrimary,
                                sky: AppColors.accentSky,
                                warm: AppColors.accentWarm,
                              ),
                            )
                          : ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.xs),
                              child: Image.asset(
                                project.imageAsset!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => CustomPaint(
                                  painter: _PlaceholderArtPainter(
                                    ink: AppColors.inkPrimary,
                                    sky: AppColors.accentSky,
                                    warm: AppColors.accentWarm,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        color: AppColors.inkPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      project.blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -AppSpacing.sm,
              left: (cardWidth - 80) / 2,
              child: IgnorePointer(
                child: SizedBox(
                  width: 80,
                  height: 26,
                  child: CustomPaint(
                    painter: _TapePainter(
                      tape: AppColors.idleGlow.withValues(alpha: 0.65),
                      edge: AppColors.inkPrimary,
                    ),
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

/// Wobbly strip of masking tape holding the polaroid up.
class _TapePainter extends CustomPainter {
  const _TapePainter({required this.tape, required this.edge});

  final Color tape;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final strip = Path()
      ..moveTo(3, 4)
      ..lineTo(size.width - 4, 1)
      ..lineTo(size.width - 1, size.height - 3)
      ..lineTo(2, size.height - 5)
      ..close();

    canvas.drawPath(strip, Paint()..color = tape..style = PaintingStyle.fill);
    canvas.drawPath(
      strip,
      Paint()
        ..color = edge.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TapePainter oldDelegate) =>
      oldDelegate.tape != tape || oldDelegate.edge != edge;
}

/// A cheap doodle scene standing in for a real project image.
class _PlaceholderArtPainter extends CustomPainter {
  const _PlaceholderArtPainter({
    required this.ink,
    required this.sky,
    required this.warm,
  });

  final Color ink;
  final Color sky;
  final Color warm;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
      Offset(w * 0.76, h * 0.24),
      w * 0.1,
      Paint()..color = warm.withValues(alpha: 0.5),
    );

    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.06, h * 0.8)
        ..lineTo(w * 0.4, h * 0.34)
        ..lineTo(w * 0.7, h * 0.8),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.38, h * 0.8)
        ..lineTo(w * 0.66, h * 0.5)
        ..lineTo(w * 0.94, h * 0.8),
      stroke..color = sky,
    );
    canvas.drawLine(
      Offset(w * 0.06, h * 0.84),
      Offset(w * 0.94, h * 0.82),
      stroke..color = ink,
    );
  }

  @override
  bool shouldRepaint(covariant _PlaceholderArtPainter oldDelegate) =>
      oldDelegate.ink != ink ||
      oldDelegate.sky != sky ||
      oldDelegate.warm != warm;
}
