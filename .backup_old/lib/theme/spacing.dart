/// Living Sketchbook spacing scale — PROJECT_PROCESS.md §5.4.
///
/// One spacing language for the whole app: `AppSpacing.md` instead of
/// scattered `12.0` literals. Guarded by test/core/theme/design_tokens_test.dart
/// (values locked + strictly increasing).
abstract final class AppSpacing {
  /// Tight coupling — icon to its label.
  static const double xs = 4;

  /// Inline gaps — inside buttons, chips.
  static const double sm = 8;

  /// Related elements — title to subtitle.
  static const double md = 12;

  /// Default gutter between siblings.
  static const double lg = 16;

  /// Section padding.
  static const double xl = 24;

  /// Card internal padding.
  static const double xxl = 32;

  /// Between major blocks.
  static const double xxxl = 48;

  /// Hero moments — idle screen, thank-you breathing room.
  static const double huge = 64;
}
