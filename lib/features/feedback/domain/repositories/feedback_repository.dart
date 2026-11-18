import 'package:ucstgo_showcase_flutter_app/core/domain/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/feedback.dart';

/// Feedback persistence contract — implemented in `data/` (§4.2).
///
/// Local-first by contract (§6.4): [submit] resolves once the row is
/// durably stored; the remote upload is best-effort and must never throw
/// network failures at the UI.
abstract interface class FeedbackRepository {
  /// Stores the submission locally (status pending), then best-effort
  /// uploads it. Returns [SubmissionAccepted] for pending/synced and
  /// [SubmissionRefused] for terminal refusals (§6.6).
  Future<SubmissionResult> submit(Feedback feedback);

  /// Rows still awaiting upload, FIFO — the SyncService drain surface
  /// (Iteration 18).
  Future<List<Feedback>> pending({int limit = 50});

  /// Applies a sync outcome to one row (§6.6). When [status] is
  /// [SyncStatus.pending], [nextRetryAt] carries the backoff deadline.
  Future<void> applySyncStatus(
    String clientId,
    SyncStatus status, {
    DateTime? nextRetryAt,
  });
}
