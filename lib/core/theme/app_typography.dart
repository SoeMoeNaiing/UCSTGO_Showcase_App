import 'package:flutter/material.dart' as material;
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography tokens for large showcase displays and kiosks.
abstract final class AppTypography {
  static material.TextTheme get textTheme => material.TextTheme(
    displayLarge: GoogleFonts.spaceGrotesk(
      fontSize: 44,
      fontWeight: material.FontWeight.w800,
      letterSpacing: -1.0,
      color: AppColors.inkPrimary,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontSize: 28,
      fontWeight: material.FontWeight.w700,
      letterSpacing: -0.5,
      color: AppColors.inkPrimary,
    ),
    titleLarge: GoogleFonts.spaceGrotesk(
      fontSize: 20,
      fontWeight: material.FontWeight.w700,
      color: AppColors.inkPrimary,
    ),
    bodyLarge: GoogleFonts.spaceGrotesk(
      fontSize: 16,
      fontWeight: material.FontWeight.w500,
      color: AppColors.inkPrimary,
    ),
    bodyMedium: GoogleFonts.spaceGrotesk(
      fontSize: 14,
      fontWeight: material.FontWeight.w400,
      color: AppColors.inkSecondary,
    ),
    labelLarge: GoogleFonts.jetBrainsMono(
      fontSize: 13,
      fontWeight: material.FontWeight.w700,
      letterSpacing: 1.1,
      color: AppColors.electricCyan,
    ),
  );
}
