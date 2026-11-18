import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Iteration 1 — Architecture structure test (PROJECT_PROCESS.md §4.1 & §4.3).
///
/// Guards the canonical folder layout so feature work can never land in the
/// wrong place: every layer directory must exist, and the test tree must mirror
/// the lib tree by layer (domain / data / presentation / services / core).
void main() {
  /// The three feature stacks that each own domain → data → presentation.
  const features = ['feedback', 'rating', 'showcase'];

  /// The 11 canonical layer directories inside every feature (§4.1).
  const featureLayers = [
    'domain/entities',
    'domain/repositories',
    'domain/usecases',
    'data/models',
    'data/datasources',
    'data/local',
    'data/local/tables',
    'data/repositories',
    'presentation/screens',
    'presentation/widgets',
    'presentation/controllers',
  ];

  /// Shared core directories (§4.1).
  const coreDirs = ['domain', 'theme', 'router', 'widgets', 'utils'];

  /// The complete canonical lib/ tree, derived from the lists above.
  final canonicalLibDirs = <String>[
    for (final dir in coreDirs) 'lib/core/$dir',
    'lib/services',
    for (final feature in features)
      for (final layer in featureLayers) 'lib/features/$feature/$layer',
  ];

  /// Test placement per §4.3: tests mirror lib by layer, not file-for-file.
  final canonicalTestDirs = <String>[
    for (final dir in coreDirs) 'test/core/$dir',
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
      // 5 core + 1 services + (3 features x 11 layers) = 39 directories.
      expect(canonicalLibDirs, hasLength(39));
    });

    test('test/ mirrors lib/ by layer (§4.3)', () {
      final missing =
          canonicalTestDirs.where((p) => !Directory(p).existsSync()).toList();

      expect(
        missing,
        isEmpty,
        reason: 'Missing test mirror directories: $missing',
      );
      // 5 core + 1 services + (3 features x 3 layers) = 15 directories.
      expect(canonicalTestDirs, hasLength(15));
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
