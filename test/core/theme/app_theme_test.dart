import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/theme/app_colors.dart';
import 'package:ucstgo_showcase_flutter_app/core/theme/app_theme.dart';
import 'package:ucstgo_showcase_flutter_app/core/theme/app_typography.dart';

/// Iteration 5 — AppTheme composition guard (PROJECT_PROCESS.md §5).
///
/// Proves the tokens actually reach widgets: scaffold paper, palette
/// color scheme, Patrick Hand type scale, card surface and the D-pad
/// focus halo. Also proves [AppTheme.light] stays pure (no font loading).
void main() {
  group('AppTheme (§5)', () {
    test('scaffold background is the paper token', () {
      expect(
        AppTheme.light.scaffoldBackgroundColor,
        AppColors.paperBackground,
      );
    });

    test('color scheme is built from the palette', () {
      final scheme = AppTheme.light.colorScheme;

      expect(scheme.primary, AppColors.accentWarm);
      expect(scheme.onPrimary, AppColors.paperWhite);
      expect(scheme.secondary, AppColors.accentSky);
      expect(scheme.surface, AppColors.paperWhite);
      expect(scheme.onSurface, AppColors.inkPrimary);
      expect(scheme.error, AppColors.accentBlush);
    });

    test('text theme carries token sizes and the locked family', () {
      final text = AppTheme.light.textTheme;

      expect(text.displayLarge?.fontSize, AppTypography.displaySize);
      expect(text.headlineMedium?.fontSize, AppTypography.headlineSize);
      expect(text.bodyLarge?.fontSize, AppTypography.bodySize);
      expect(text.bodyMedium?.fontSize, AppTypography.bodySize);
      expect(text.bodySmall?.fontSize, AppTypography.captionSize);

      for (final style in <TextStyle?>[
        text.displayLarge,
        text.headlineMedium,
        text.bodyLarge,
        text.bodyMedium,
        text.bodySmall,
      ]) {
        expect(
          style?.fontFamily,
          AppTypography.family,
          reason: 'Every themed style must use the locked family',
        );
      }
    });

    test('cards and focus halo use palette tokens', () {
      final theme = AppTheme.light;

      expect(theme.cardTheme.color, AppColors.paperWhite);
      expect(theme.cardTheme.elevation, 0);
      expect(
        theme.focusColor,
        AppColors.accentWarm.withValues(alpha: 0.25),
      );
    });

    testWidgets('themed app paints paper and token body style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: Text('Living Sketchbook')),
        ),
      );

      final context = tester.element(find.text('Living Sketchbook'));
      final theme = Theme.of(context);

      expect(theme.scaffoldBackgroundColor, AppColors.paperBackground);

      final defaultStyle = DefaultTextStyle.of(context).style;
      expect(defaultStyle.fontFamily, AppTypography.family);
      expect(defaultStyle.fontSize, AppTypography.bodySize);
    });

    testWidgets('Card renders on the paper-white surface token', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Card(
              child: SizedBox(height: 20, width: 20),
            ),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(Card),
          matching: find.byType(Material),
        ),
      );

      expect(material.color, AppColors.paperWhite);
    });
  });
}
