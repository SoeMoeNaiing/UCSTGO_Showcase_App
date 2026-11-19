import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/project.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Cyber-Brutalist Maximalist showcase card preserving semantics,
/// [cardWidth], [cardHeight], [focusNode], and [onSelect].
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onSelect,
    this.autofocus = false,
    this.focusNode,
  });

  final Project project;
  final ValueChanged<Project> onSelect;
  final bool autofocus;
  final FocusNode? focusNode;

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
        child:
            Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      focusNode: focusNode,
                      autofocus: autofocus,
                      onTap: _select,
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      child: Container(
                        width: cardWidth,
                        height: cardHeight,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.paperWhite,
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                          border: Border.all(
                            color: AppColors.accentSky,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.accentWarm,
                              offset: Offset(6, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.paperShadow,
                                    width: 1.5,
                                  ),
                                ),
                                child: project.imageAsset == null
                                    ? CustomPaint(
                                        painter: _CyberArtPainter(
                                          ink: AppColors.inkPrimary,
                                          sky: AppColors.accentSky,
                                          warm: AppColors.accentWarm,
                                        ),
                                      )
                                    : Image.asset(
                                        project.imageAsset!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => CustomPaint(
                                          painter: _CyberArtPainter(
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
                      left: (cardWidth - 84) / 2,
                      child: IgnorePointer(
                        child: Container(
                          width: 84,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.idleGlow,
                            border: Border.all(
                              color: AppColors.paperBackground,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'SPEC // 01',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.paperBackground,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .moveY(
                  begin: 0,
                  end: -3,
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.easeInOut,
                ),
      ),
    );
  }
}

class _CyberArtPainter extends CustomPainter {
  const _CyberArtPainter({
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
      Offset(w * 0.78, h * 0.24),
      w * 0.11,
      Paint()..color = warm.withValues(alpha: 0.75),
    );

    final stroke = Paint()
      ..color = sky
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.square;

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.08, h * 0.8)
        ..lineTo(w * 0.42, h * 0.34)
        ..lineTo(w * 0.72, h * 0.8),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.38, h * 0.8)
        ..lineTo(w * 0.66, h * 0.48)
        ..lineTo(w * 0.94, h * 0.8),
      stroke..color = warm,
    );
    canvas.drawLine(
      Offset(w * 0.08, h * 0.84),
      Offset(w * 0.92, h * 0.84),
      Paint()
        ..color = ink
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant _CyberArtPainter oldDelegate) =>
      oldDelegate.ink != ink ||
      oldDelegate.sky != sky ||
      oldDelegate.warm != warm;
}
