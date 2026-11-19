import 'rating.dart';

/// One due rating row plus its persisted attempt count (§6.4, §13).
///
/// The count comes from the durable Drift row so a restart resumes the
/// backoff ladder instead of resetting it.
final class QueuedRating {
  const QueuedRating({
    required this.rating,
    required this.attempts,
  });

  final Rating rating;

  /// Failed attempts already recorded (`0` = never tried).
  final int attempts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueuedRating &&
          other.rating == rating &&
          other.attempts == attempts;

  @override
  int get hashCode => Object.hash(rating, attempts);

  @override
  String toString() =>
      'QueuedRating(clientId: ${rating.clientId}, attempts: $attempts)';
}
