import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/entities/rating.dart';

/// Iteration 8 — Rating entity invariants (PROJECT_PROCESS.md §6.1, §6.5).
void main() {
  const clientId = '0c2a4d7e-1b2c-4d5e-8f90-112233445566';
  const deviceId = 'device-0001';
  final createdAt = DateTime.utc(2026, 11, 18, 11);

  Rating build({
    String client = clientId,
    String device = deviceId,
    String project = 'project-01',
    int score = 4,
    DateTime? at,
  }) {
    return Rating(
      clientId: client,
      deviceId: device,
      projectId: project,
      score: score,
      createdAt: at ?? createdAt,
    );
  }

  group('Rating entity (§6.1, §6.5)', () {
    test('accepts the full 1–5 score range', () {
      expect(build(score: 1).score, 1);
      expect(build(score: 5).score, 5);
    });

    test('rejects scores outside 1–5', () {
      expect(() => build(score: 0), throwsA(isA<AssertionError>()));
      expect(() => build(score: 6), throwsA(isA<AssertionError>()));
      expect(() => build(score: -1), throwsA(isA<AssertionError>()));
    });

    test('rejects empty identifiers', () {
      expect(() => build(client: ''), throwsA(isA<AssertionError>()));
      expect(() => build(device: ''), throwsA(isA<AssertionError>()));
      expect(() => build(project: ''), throwsA(isA<AssertionError>()));
    });

    test('requires UTC createdAt', () {
      expect(
        () => build(at: DateTime(2026, 11, 18, 11)),
        throwsA(isA<AssertionError>()),
      );
      expect(build().createdAt.isUtc, isTrue);
    });

    test('equality is value-based', () {
      final first = build();
      final replay = build();

      expect(identical(first, replay), isFalse);
      expect(first, replay);
      expect(first.hashCode, replay.hashCode);
    });

    test('any differing field breaks equality', () {
      final base = build();

      expect(base, isNot(build(client: 'other-client')));
      expect(base, isNot(build(device: 'device-0002')));
      expect(base, isNot(build(project: 'project-02')));
      expect(base, isNot(build(score: 5)));
      expect(base, isNot(build(at: DateTime.utc(2026, 11, 18, 11, 1))));
    });

    test('toString is log-safe and identifies the rating', () {
      final text = build().toString();

      expect(text, contains(clientId));
      expect(text, contains('project-01'));
      expect(text, contains('score: 4'));
    });
  });
}
