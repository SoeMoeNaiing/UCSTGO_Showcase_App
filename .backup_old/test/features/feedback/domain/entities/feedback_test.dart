import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/models/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/models/feedback.dart';

/// Iteration 7 — Feedback entity invariants (PROJECT_PROCESS.md §6.5).
void main() {
  const clientId = '8f14e45f-ceea-467a-8f7e-1b2c3d4e5f60';
  const deviceId = 'device-0001';
  final createdAt = DateTime.utc(2026, 11, 18, 10, 30);

  Feedback build({
    String client = clientId,
    String device = deviceId,
    EmojiChoice choice = EmojiChoice.satisfied,
    DateTime? at,
  }) {
    return Feedback(
      clientId: client,
      deviceId: device,
      emojiChoice: choice,
      createdAt: at ?? createdAt,
    );
  }

  group('Feedback entity (§6.5)', () {
    test('clientId is required — empty idempotency key fails fast', () {
      expect(() => build(client: ''), throwsA(isA<AssertionError>()));
    });

    test('deviceId is required', () {
      expect(() => build(device: ''), throwsA(isA<AssertionError>()));
    });

    test('createdAt must be UTC (queue + timestamptz contract)', () {
      expect(
        () => build(at: DateTime(2026, 11, 18, 10, 30)),
        throwsA(isA<AssertionError>()),
      );
      expect(build(at: createdAt).createdAt.isUtc, isTrue);
    });

    test('equality is value-based — idempotent replays compare equal', () {
      final first = build();
      final replay = build();

      expect(identical(first, replay), isFalse);
      expect(first, replay);
      expect(first.hashCode, replay.hashCode);
    });

    test('any differing field breaks equality', () {
      final base = build();

      expect(base, isNot(build(client: 'other-client-id')));
      expect(base, isNot(build(device: 'device-0002')));
      expect(base, isNot(build(choice: EmojiChoice.dissatisfied)));
      expect(base, isNot(build(at: DateTime.utc(2026, 11, 18, 10, 31))));
    });

    test('toString is log-safe and identifies the submission', () {
      final text = build().toString();

      expect(text, contains(clientId));
      expect(text, contains('satisfied'));
      expect(text, contains('2026-11-18T10:30:00.000Z'));
    });
  });
}
