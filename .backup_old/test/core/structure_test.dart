import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Iteration 1 — Architecture structure test (PROJECT_PROCESS.md §4.1 & §4.3).
///
/// Guards the canonical folder layout. After the I33 simplification the lib
/// tree is flat by responsibility: controllers / database / models /
/// repositories / router / screens / services / theme / widgets.
void main() {
  /// Canonical lib/ directories after the flat refactor.
  const canonicalLibDirs = <String>[
    'lib/controllers',
    'lib/database',
    'lib/models',
    'lib/repositories',
    'lib/router',
    'lib/screens',
    'lib/services',
    'lib/theme',
    'lib/widgets',
  ];

  /// Tests remain grouped by feature/layer for traceability.
  const features = ['feedback', 'rating', 'showcase'];
  final canonicalTestDirs = <String>[
    'test/core/domain',
    'test/core/theme',
    'test/core/widgets',
    'test/services',
    for (final feature in features)
      for (final layer in ['domain', 'data', 'presentation'])
        'test/features/$feature/$layer',
  ];

  group('Architecture structure (§4.1)', () {
    test('every canonical lib/ directory exists', () {
      final missing =
          canonicalLibDirs.where((p) => !Directory(p).existsSync()).toList();

      expect(
        missing,
        isEmpty,
        reason: 'Missing canonical lib/ directories: $missing',
      );
      expect(canonicalLibDirs, hasLength(9));
    });

    test('test groups are present by domain/data/presentation (§4.3)', () {
      final missing =
          canonicalTestDirs.where((p) => !Directory(p).existsSync()).toList();

      expect(
        missing,
        isEmpty,
        reason: 'Missing test mirror directories: $missing',
      );
      // 5 core + 1 services + (3 features x 3 layers) = 15 directories.
      expect(canonicalTestDirs, hasLength(13));
    });

    test('process docs and tool configs are present at repo root', () {
      const rootFiles = [
        'PROJECT_PROCESS.md',
        'README.md',
        'pubspec.yaml',
        'analysis_options.yaml',
      ];

      for (final file in rootFiles) {
        expect(
          File(file).existsSync(),
          isTrue,
          reason: '$file must exist at the repository root',
        );
      }
    });
  });
}
