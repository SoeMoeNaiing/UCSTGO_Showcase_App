import 'package:ucstgo_showcase_flutter_app/core/domain/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/entities/rating.dart';

/// Rating persistence contract — implemented in `data/` (Phase 4).
///
/// Mirrors [FeedbackRepository] on purpose: ratings ride the same
/// local-first queue and sync engine (§6.4), just on their own table.
abstract interface class RatingRepository {
  /// Stores the rating locally (status pending), then best-effort uploads
  /// it. Returns [SubmissionAccepted] for pending/synced and
  /// [SubmissionRefused] for terminal refusals (§6.6).
  Future<SubmissionResult> submit(Rating rating);

  /// Rows still awaiting upload, FIFO — the SyncService drain surface
  /// (Iteration 33 plugs this queue in).
  Future<List<Rating>> pending({int limit = 50});

  /// Applies a sync outcome to one row (§6.6). When [status] is
  /// [SyncStatus.pending], [nextRetryAt] carries the backoff deadline.
  Future<void> applySyncStatus(
    String clientId,
    SyncStatus status, {
    DateTime? nextRetryAt,
  });
}
