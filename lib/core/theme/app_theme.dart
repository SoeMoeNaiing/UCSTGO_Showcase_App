import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.voidBlack,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.electricCyan,
      onPrimary: AppColors.voidBlack,
      secondary: AppColors.hyperCoral,
      onSecondary: AppColors.voidBlack,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.inkPrimary,
      error: AppColors.neonMagenta,
      onError: AppColors.inkPrimary,
    ),
    textTheme: AppTypography.textTheme,
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(
          color: AppColors.electricCyan,
          width: AppSpacing.borderThin,
        ),
      ),
    ),
  );
}
