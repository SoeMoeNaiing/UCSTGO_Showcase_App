import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import './colors.dart';
import './spacing.dart';
import './typography.dart';

/// Composes the Cyber-Brutalist Maximalist [ThemeData] from design tokens.
///
/// * [light] is **pure** — tokens in, [ThemeData] out. No binding, no
///   network, fully hermetic for unit/widget tests.
/// * [loadFonts] registers the Patrick Hand face with the engine. Call from
///   `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
abstract final class AppTheme {
  /// The single source of truth for app theming (no hardcoded values).
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentWarm,
      onPrimary: AppColors.paperBackground,
      secondary: AppColors.accentSky,
      onSecondary: AppColors.paperBackground,
      surface: AppColors.paperWhite,
      onSurface: AppColors.inkPrimary,
      error: AppColors.accentBlush,
      onError: AppColors.inkPrimary,
    ),
    scaffoldBackgroundColor: AppColors.paperBackground,
    textTheme: const TextTheme(
      displayLarge: AppTypography.display,
      headlineMedium: AppTypography.headline,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.caption,
    ),
    cardTheme: CardThemeData(
      color: AppColors.paperWhite,
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        side: const BorderSide(color: AppColors.accentSky, width: 2),
      ),
    ),
    focusColor: AppColors.accentWarm.withValues(alpha: 0.28),
    splashFactory: InkRipple.splashFactory,
  );

  /// Registers the Patrick Hand face (google_fonts). Call once from
  /// `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
  static void loadFonts() {
    GoogleFonts.patrickHand();
  }
}
