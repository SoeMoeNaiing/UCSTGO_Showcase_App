import 'package:ucstgo_showcase_flutter_app/core/domain/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/entities/queued_rating.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/entities/rating.dart';

/// Rating persistence contract — implemented in `data/` (§4.2).
///
/// Mirrors `FeedbackRepository` on purpose: ratings ride the same
/// local-first queue and sync engine, just on their own Drift table.
abstract interface class RatingRepository {
  /// Stores the rating locally first, then best-effort uploads it.
  /// Never throws a network failure at the UI (§6.4).
  Future<SubmissionResult> submit(Rating rating);

  /// Due rows, FIFO, with persisted attempt counts for backoff.
  Future<List<QueuedRating>> pending({int limit = 50});

  /// Live count of rows awaiting upload, including backoff-waiting rows.
  Stream<int> watchPendingCount();

  /// Applies a sync outcome to one row (§6.6).
  Future<void> applySyncStatus(
    String clientId,
    SyncStatus status, {
    DateTime? nextRetryAt,
  });
}
