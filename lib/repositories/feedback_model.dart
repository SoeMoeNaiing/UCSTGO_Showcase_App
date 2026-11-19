import '../models/emoji_choice.dart';
import '../models/feedback.dart';

/// Wire DTO for one feedback submission — PROJECT_PROCESS.md §6.2.
///
/// Exactly the three client-supplied keys the `submit-feedback` Edge
/// Function accepts. `ip_hash` is derived server-side and `created_at` is
/// assigned by the database (`now()`), so neither belongs in the payload;
/// the local Drift row still records the visit time for FIFO ordering.
///
/// Parsing is strict: missing/blank ids or an unknown emoji throw
/// [FormatException] instead of silently coercing data into the stats.
final class FeedbackModel {
  const FeedbackModel({
    required this.clientId,
    required this.deviceId,
    required this.emojiChoice,
  });

  /// Builds the transport payload from the local entity.
  factory FeedbackModel.fromFeedback(Feedback feedback) => FeedbackModel(
        clientId: feedback.clientId,
        deviceId: feedback.deviceId,
        emojiChoice: feedback.emojiChoice,
      );

  /// Parses the exact wire shape. Extra server fields are ignored.
  factory FeedbackModel.fromJson(Map<String, Object?> json) {
    final clientId = json['client_id'];
    if (clientId is! String || clientId.trim().isEmpty) {
      throw const FormatException('client_id is required');
    }

    final deviceId = json['device_id'];
    if (deviceId is! String || deviceId.trim().isEmpty) {
      throw const FormatException('device_id is required');
    }

    final emojiChoice = json['emoji_choice'];
    if (emojiChoice is! String) {
      throw const FormatException('emoji_choice is required');
    }

    return FeedbackModel(
      clientId: clientId,
      deviceId: deviceId,
      emojiChoice: EmojiChoice.fromJson(emojiChoice),
    );
  }

  /// Client-generated idempotency key (§6.5).
  final String clientId;

  /// Anonymous persistent device identifier (§6.3).
  final String deviceId;

  /// The visitor's selection.
  final EmojiChoice emojiChoice;

  /// Exact §6.2 payload — three keys, no more.
  Map<String, Object?> toJson() => {
        'client_id': clientId,
        'device_id': deviceId,
        'emoji_choice': emojiChoice.wireValue,
      };

  /// Rehydrates the domain entity.
  ///
  /// [createdAt] comes from the local row because the payload does not carry
  /// time; a local value is normalized to UTC to satisfy the entity contract.
  Feedback toFeedback({required DateTime createdAt}) => Feedback(
        clientId: clientId,
        deviceId: deviceId,
        emojiChoice: emojiChoice,
        createdAt: createdAt.toUtc(),
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FeedbackModel &&
            other.clientId == clientId &&
            other.deviceId == deviceId &&
            other.emojiChoice == emojiChoice;
  }

  @override
  int get hashCode => Object.hash(clientId, deviceId, emojiChoice);

  @override
  String toString() =>
      'FeedbackModel(clientId: $clientId, emojiChoice: '
      '${emojiChoice.wireValue})';
}
