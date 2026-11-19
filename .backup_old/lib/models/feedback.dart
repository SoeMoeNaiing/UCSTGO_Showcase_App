import './emoji_choice.dart';

/// A single piece of visitor feedback — PROJECT_PROCESS.md §1.1, §6.5.
///
/// Pure domain entity: no Flutter, no Supabase, no JSON transport concerns
/// (the DTO lives in `data/models/feedback_model.dart`, Iteration 12).
///
/// [clientId] is the **idempotency key** (§6.5): generated once on the
/// device *before* the local write, reused on every retry, and UNIQUE on
/// the server (`ON CONFLICT (client_id) DO NOTHING`). Without it, a
/// timeout-retry could double-count feedback.
///
/// [createdAt] must be **UTC**: the queue orders by it and the server stores
/// `timestamptz`; local-time values would make ordering timezone-dependent.
final class Feedback {
  Feedback({
    required this.clientId,
    required this.deviceId,
    required this.emojiChoice,
    required this.createdAt,
  }) : assert(clientId != '', 'clientId is the idempotency key — required'),
       assert(deviceId != '', 'deviceId is required (anonymous identity)'),
       assert(
         createdAt.isUtc,
         'createdAt must be UTC (queue + server contract)',
       );

  /// Client-generated UUID v4 — the idempotency key (§6.5).
  final String clientId;

  /// Anonymous persistent device identifier (no PII, §2.4).
  final String deviceId;

  /// The visitor's emoji selection.
  final EmojiChoice emojiChoice;

  /// When the visitor submitted, in UTC.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Feedback &&
            other.clientId == clientId &&
            other.deviceId == deviceId &&
            other.emojiChoice == emojiChoice &&
            other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(clientId, deviceId, emojiChoice, createdAt);

  @override
  String toString() =>
      'Feedback(clientId: $clientId, emojiChoice: '
      '${emojiChoice.wireValue}, createdAt: ${createdAt.toIso8601String()})';
}
