import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Iteration 7 — Domain purity guard (PROJECT_PROCESS.md §4.2).
///
/// The domain layer is pure Dart: no Flutter, no Supabase, no dart:ui.
/// Anything that needs those belongs in data/ or services/. This test
/// enforces the layer boundary mechanically instead of relying on review.
void main() {
  test('domain layers import no Flutter, Supabase or dart:ui (§4.2)', () {
    const forbidden = <String>[
      "import 'package:flutter/",
      "import 'package:flutter_test/",
      "import 'package:supabase_flutter/",
      "import 'package:supabase/",
      "import 'dart:ui'",
    ];

    final offenders = <String>[];
    final features = Directory('lib/features');

    for (final feature in features.listSync().whereType<Directory>()) {
      final domain = Directory('${feature.path}/domain');
      if (!domain.existsSync()) continue;

      for (final file in domain.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;

        final source = file.readAsStringSync();
        for (final import in forbidden) {
          if (source.contains(import)) {
            offenders.add('${file.path} → $import');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Domain must stay pure Dart (§4.2). Offenders: $offenders',
    );
  });
}
