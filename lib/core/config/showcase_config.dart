/// Central configuration for the UCSTGO Showcase Display.
abstract final class ShowcaseConfig {
  /// Campus display title.
  static const String institutionName =
      'UNIVERSITY OF COMPUTER STUDIES, TAUNGOO';

  /// Event / showcase subtitle.
  static const String showcaseTagline =
      'ANNUAL TECH SHOWCASE // LIVE INTERACTIVE DISPLAY';

  /// Network image URL for the university campus showcase banner.
  /// Swap this with your official UCSTGO campus photo URL anytime.
  static const String universityImageUrl =
      'https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=1400&q=85';

  /// Injected at build/run time via `--dart-define-from-file=dart_defines.json`.
  /// Defaults to empty string for offline local-only mode.
  static const String googleSheetsWebhookUrl = String.fromEnvironment(
    'SHEETS_WEBHOOK_URL',
    defaultValue: '',
  );

  static bool get hasRemoteWebhook =>
      googleSheetsWebhookUrl.trim().startsWith('https://');
}