import 'package:flutter/material.dart';

/// Living Sketchbook typography tokens — PROJECT_PROCESS.md §5.3.
///
/// Family locked at Iteration 4: **Patrick Hand** — a handwriting face
/// designed for readability, which matters at 10-foot TV distance; the §13
/// alternative (Caveat) degrades at body sizes.
///
/// [family] is the exact name google_fonts registers the face under
/// (`'PatrickHand'`), so AppTheme (Iteration 5) wires loading with
/// `GoogleFonts.patrickHandTextTheme()` and the names line up.
///
/// Tokens are pure `const` [TextStyle]s on purpose: no font loading, no
/// network, no binding — fully hermetic unit tests (§8.1).
abstract final class AppTypography {
  /// Registered font family name (must match google_fonts' registration).
  static const String family = 'PatrickHand';

  // --- Size tokens: §5.3 ranges, concrete values locked here. ---

  /// TV headlines — §5.3 range 48–64sp, locked at 56.
  static const double displaySize = 56;

  /// Section headlines — §5.3 range 32–40sp, locked at 36.
  static const double headlineSize = 36;

  /// Body — §5.3 range 20–24sp, locked at 22 (phone-first; the TV audit at
  /// Iteration 42 promotes anything below [tvMinimumSize]).
  static const double bodySize = 22;

  /// Captions — §5.3 hard minimum.
  static const double captionSize = 16;

  /// §5.5 TV floor: anything a visitor *must* read on TV is ≥ 32sp.
  static const double tvMinimumSize = 32;

  // --- Styles (sizes only; colors are decided by the theme, §2.1.4). ---

  static const TextStyle display =
      TextStyle(fontFamily: family, fontSize: displaySize);

  static const TextStyle headline =
      TextStyle(fontFamily: family, fontSize: headlineSize);

  static const TextStyle body =
      TextStyle(fontFamily: family, fontSize: bodySize);

  static const TextStyle caption =
      TextStyle(fontFamily: family, fontSize: captionSize);
}
