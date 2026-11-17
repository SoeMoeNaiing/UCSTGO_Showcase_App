import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Iteration 3 — Analysis rules guard (PROJECT_PROCESS.md §3 "Linting" & §10.3).
///
/// The strict lint configuration is a project decision, not a preference.
/// This test fails if anyone removes the base include, drops a strict rule,
/// or strips the analyzer exclusions — the same "architecture-as-test"
/// approach as test/core/structure_test.dart.
void main() {
  final yaml = File('analysis_options.yaml').readAsStringSync();

  group('Analysis configuration (Iteration 3)', () {
    test('extends the flutter_lints base ruleset', () {
      expect(
        yaml,
        contains('package:flutter_lints/flutter.yaml'),
        reason: 'analysis_options.yaml must keep the flutter_lints include',
      );
    });

    test('strict rules are explicitly enabled', () {
      const strictRules = [
        'prefer_single_quotes',
        'require_trailing_commas',
        'avoid_print',
      ];

      for (final rule in strictRules) {
        expect(
          yaml,
          contains('$rule: true'),
          reason: 'Strict rule "$rule" must stay enabled (§3 linting)',
        );
      }
    });

    test('analyzer exclusions for generated/platform dirs are kept', () {
      const exclusions = ['build/**', 'android/**', 'web/**'];

      for (final dir in exclusions) {
        expect(
          yaml,
          contains(dir),
          reason: 'Exclusion "$dir" must stay (generated code is noisy)',
        );
      }
    });
  });
}
