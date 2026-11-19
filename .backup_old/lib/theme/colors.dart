import 'package:flutter/material.dart';

/// Cyber-Brutalist Maximalist color tokens.
///
/// This is the ONLY file in the entire project allowed to contain raw
/// hex color literals (guarded by test/core/theme/design_tokens_test.dart).
abstract final class AppColors {
  /// Primary void-obsidian backdrop.
  static const paperBackground = Color(0xFF0A0B0F);

  /// Hard structural shadow / brutalist offset & grid border.
  static const paperShadow = Color(0xFF222638);

  /// Primary high-contrast foreground / crisp ink.
  static const inkPrimary = Color(0xFFF4F6FF);

  /// Secondary telemetry / body ink.
  static const inkSecondary = Color(0xFF9AA3C7);

  /// Primary cyber accent — hyper coral-orange / neon ember.
  static const accentWarm = Color(0xFFFF4D2D);

  /// Secondary cyber accent — electric cyan.
  static const accentSky = Color(0xFF00E5FF);

  /// Positive / satisfied — acid volt lime.
  static const accentSage = Color(0xFF39FF88);

  /// Negative / dissatisfied — hot cyber magenta-coral.
  static const accentBlush = Color(0xFFFF2E7E);

  /// Elevated brutalist panel surface.
  static const paperWhite = Color(0xFF141722);

  /// High-energy cyber gold / beacon yellow.
  static const idleGlow = Color(0xFFFFD600);
}
