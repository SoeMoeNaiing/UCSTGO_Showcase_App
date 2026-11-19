import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import './colors.dart';
import './spacing.dart';
import './typography.dart';

/// Composes the Living Sketchbook [ThemeData] from design tokens.
/// PROJECT_PROCESS.md §4.1 (`core/theme/app_theme.dart`) and §5.
///
/// Two deliberate API surfaces:
///
/// * [light] is **pure** — tokens in, [ThemeData] out. No binding, no
///   network, fully hermetic for unit/widget tests (§8.1).
/// * [loadFonts] registers the Patrick Hand face with the engine. It is
///   bootstrap-only (called from `main()`), never from tests.
abstract final class AppTheme {
  /// The single source of truth for app theming (no hardcoded values).
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accentWarm,
          onPrimary: AppColors.paperWhite,
          secondary: AppColors.accentSky,
          onSecondary: AppColors.inkPrimary,
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
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
        ),
        // Focus is a first-class state for D-pad (§2.3.2): warm halo built
        // from the accent token.
        focusColor: AppColors.accentWarm.withValues(alpha: 0.25),
        // Ripple instead of M3's sparkle: cheaper on low-end GPUs (§2.3.3).
        splashFactory: InkRipple.splashFactory,
      );

  /// Registers the Patrick Hand face (google_fonts). Call once from
  /// `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
  ///
  /// Deferred to bootstrap so [light] stays hermetic and tests never
  /// trigger network or binding access.
  static void loadFonts() {
    GoogleFonts.patrickHand();
  }
}
