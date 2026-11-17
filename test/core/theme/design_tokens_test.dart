import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/theme/app_colors.dart';
import 'package:ucstgo_showcase_flutter_app/core/theme/app_spacing.dart';
import 'package:ucstgo_showcase_flutter_app/core/theme/app_typography.dart';

/// Iteration 4 — Design token guard (PROJECT_PROCESS.md §5.2–§5.4).
///
/// Locks the Living Sketchbook palette, spacing scale and type scale as
/// executable specs. Also enforces §2.1.4: raw hex may exist in exactly
/// one file (app_colors.dart) and nowhere else under lib/.
void main() {
  group('AppColors (§5.2)', () {
    test('all ten tokens match the locked palette', () {
      expect(AppColors.paperBackground, const Color(0xFFF7F3EA));
      expect(AppColors.paperShadow, const Color(0xFFE5DFD0));
      expect(AppColors.inkPrimary, const Color(0xFF2B2B2B));
      expect(AppColors.inkSecondary, const Color(0xFF5C5C5C));
      expect(AppColors.accentWarm, const Color(0xFFFF6B4A));
      expect(AppColors.accentSky, const Color(0xFF7FB5D6));
      expect(AppColors.accentSage, const Color(0xFFA8C09A));
      expect(AppColors.accentBlush, const Color(0xFFF5A8A0));
      expect(AppColors.paperWhite, const Color(0xFFFFFFFF));
      expect(AppColors.idleGlow, const Color(0xFFFFD166));
    });

    test('every token is fully opaque (no accidental transparency)', () {
      final tokens = <String, Color>{
        'paperBackground': AppColors.paperBackground,
        'paperShadow': AppColors.paperShadow,
        'inkPrimary': AppColors.inkPrimary,
        'inkSecondary': AppColors.inkSecondary,
        'accentWarm': AppColors.accentWarm,
        'accentSky': AppColors.accentSky,
        'accentSage': AppColors.accentSage,
        'accentBlush': AppColors.accentBlush,
        'paperWhite': AppColors.paperWhite,
        'idleGlow': AppColors.idleGlow,
      };

      for (final entry in tokens.entries) {
        expect(
          entry.value.a,
          1.0,
          reason: 'AppColors.${entry.key} must be opaque',
        );
      }
    });

    test('raw hex literals appear nowhere else under lib/ (§2.1.4)', () {
      final offenders = <String>[];

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File) continue;
        if (entity.path.endsWith('app_colors.dart')) continue; // the one file
        if (entity.readAsStringSync().contains('0xFF')) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Raw hex colors belong only in app_colors.dart. '
            'Offenders: $offenders',
      );
    });
  });

  group('AppSpacing (§5.4)', () {
    test('scale matches the locked values', () {
      expect(
        [
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xxxl,
          AppSpacing.huge,
        ],
        [4, 8, 12, 16, 24, 32, 48, 64],
      );
    });

    test('scale is strictly increasing (no duplicate steps)', () {
      final values = [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.huge,
      ];

      for (var i = 1; i < values.length; i++) {
        expect(
          values[i],
          greaterThan(values[i - 1]),
          reason: 'AppSpacing step $i must exceed step ${i - 1}',
        );
      }
    });
  });

  group('AppTypography (§5.3)', () {
    test('sizes are locked within the documented ranges', () {
      expect(AppTypography.displaySize, inInclusiveRange(48, 64));
      expect(AppTypography.headlineSize, inInclusiveRange(32, 40));
      expect(AppTypography.bodySize, inInclusiveRange(20, 24));
      expect(AppTypography.captionSize, 16, reason: '§5.3 hard minimum');
      expect(AppTypography.tvMinimumSize, 32, reason: '§5.5 TV floor');
    });

    test('style getters carry the locked size and family', () {
      expect(AppTypography.display.fontSize, AppTypography.displaySize);
      expect(AppTypography.headline.fontSize, AppTypography.headlineSize);
      expect(AppTypography.body.fontSize, AppTypography.bodySize);
      expect(AppTypography.caption.fontSize, AppTypography.captionSize);

      expect(
        AppTypography.body.fontFamily,
        'PatrickHand',
        reason: 'Font family locked to Patrick Hand at Iteration 4 (§13); '
            'the string must match google_fonts’ registration so '
            'AppTheme can wire it in Iteration 5.',
      );
      expect(AppTypography.family, 'PatrickHand');
    });
  });
}
