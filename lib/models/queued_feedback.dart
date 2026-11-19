import './feedback.dart';

/// One due row of the local queue — the entity plus local attempt metadata.
///
/// The attempt count belongs to the queue, not the visitor's feedback: it is
/// written by the local datasource when a retry is scheduled and must survive
/// an app restart so the exponential backoff continues instead of resetting.
final class QueuedFeedback {
  const QueuedFeedback({
    required this.feedback,
    required this.attempts,
  });

  /// The durable submission to upload.
  final Feedback feedback;

  /// Failed attempts already recorded (`0` = never tried).
  ///
  /// Also selects the backoff step: attempts `0` waits 2s, `1` waits 4s, …
  final int attempts;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QueuedFeedback &&
            other.feedback == feedback &&
            other.attempts == attempts;
  }

  @override
  int get hashCode => Object.hash(feedback, attempts);

  @override
  String toString() =>
      'QueuedFeedback(clientId: ${feedback.clientId}, attempts: $attempts)';
}
