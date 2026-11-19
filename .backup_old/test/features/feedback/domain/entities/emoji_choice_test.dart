import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/models/emoji_choice.dart';

/// Iteration 7 — EmojiChoice wire contract (PROJECT_PROCESS.md §6.1).
void main() {
  group('EmojiChoice (§6.1 wire contract)', () {
    test('has exactly the three documented choices', () {
      expect(EmojiChoice.values, hasLength(3));
      expect(
        EmojiChoice.values.map((choice) => choice.wireValue),
        ['satisfied', 'neutral', 'dissatisfied'],
      );
    });

    test('toJson serializes each choice to its wire value', () {
      expect(EmojiChoice.satisfied.toJson(), 'satisfied');
      expect(EmojiChoice.neutral.toJson(), 'neutral');
      expect(EmojiChoice.dissatisfied.toJson(), 'dissatisfied');
    });

    test('fromJson round-trips every value', () {
      for (final choice in EmojiChoice.values) {
        expect(EmojiChoice.fromJson(choice.toJson()), choice);
      }
    });

    test('unknown wire values throw instead of silently coercing', () {
      expect(() => EmojiChoice.fromJson('ecstatic'), throwsFormatException);
      expect(() => EmojiChoice.fromJson(''), throwsFormatException);
      expect(() => EmojiChoice.fromJson('Satisfied'), throwsFormatException);
    });
  });
}
