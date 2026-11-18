/// Visitor sentiment choice — PROJECT_PROCESS.md §5.1 and §6.1.
///
/// Wire values are part of the database contract (`emoji_choice text`):
/// `'satisfied'`, `'neutral'`, `'dissatisfied'`. Adding a new choice later
/// means updating the Supabase schema docs, the Edge Function validation
/// and this enum together — never silently renaming a wire value.
enum EmojiChoice {
  satisfied('satisfied'),
  neutral('neutral'),
  dissatisfied('dissatisfied');

  const EmojiChoice(this.wireValue);

  /// Canonical value persisted locally and sent to the Edge Function.
  final String wireValue;

  /// Serializes for transport (DOMAIN-level value, not a DTO concern).
  String toJson() => wireValue;

  /// Parses a wire value; an unknown value is a bug, not something to
  /// silently coerce — it would corrupt feedback statistics.
  static EmojiChoice fromJson(String value) {
    for (final choice in values) {
      if (choice.wireValue == value) {
        return choice;
      }
    }
    throw FormatException('Unknown EmojiChoice wire value: "$value"');
  }
}
