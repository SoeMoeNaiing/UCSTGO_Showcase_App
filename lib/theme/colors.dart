import 'package:flutter/material.dart';

/// Living Sketchbook color tokens — PROJECT_PROCESS.md §5.2.
///
/// This is the ONLY file in the entire project allowed to contain raw
/// hex color literals (guarded by test/core/theme/design_tokens_test.dart).
/// Every widget sources colors from here; hardcoding `Color(0xFF...)`
/// anywhere else fails the test suite.
abstract final class AppColors {
  /// Main background — warm off-white paper.
  static const paperBackground = Color(0xFFF7F3EA);

  /// Card shadows and paper edges.
  static const paperShadow = Color(0xFFE5DFD0);

  /// Primary text and sketch strokes.
  static const inkPrimary = Color(0xFF2B2B2B);

  /// Secondary/body text.
  static const inkSecondary = Color(0xFF5C5C5C);

  /// Primary accent — active highlights, focus glow.
  static const accentWarm = Color(0xFFFF6B4A);

  /// Secondary accent.
  static const accentSky = Color(0xFF7FB5D6);

  /// Positive feedback (satisfied).
  static const accentSage = Color(0xFFA8C09A);

  /// Negative feedback (dissatisfied).
  static const accentBlush = Color(0xFFF5A8A0);

  /// Card surfaces.
  static const paperWhite = Color(0xFFFFFFFF);

  /// Idle-mode glow accent.
  static const idleGlow = Color(0xFFFFD166);
}
