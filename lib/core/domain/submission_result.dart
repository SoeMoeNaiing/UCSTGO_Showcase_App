import 'sync_status.dart';

/// Outcome of a local-first submit — PROJECT_PROCESS.md §4.2, §6.4, §6.6.
///
/// The UI must react identically whether the upload happened now
/// ([SyncStatus.synced]) or will happen later ([SyncStatus.pending]):
/// both are [SubmissionAccepted] and show the thank-you screen.
///
/// Sealed on purpose: adding a third variant later forces every `switch`
/// in the app to handle it (compile-time exhaustiveness).
sealed class SubmissionResult {
  const SubmissionResult(this.status);

  /// Local status of the row after the submit attempt.
  final SyncStatus status;
}

/// The submission is durably stored and safe.
///
/// [status] is either [SyncStatus.pending] (offline / remote failed —
/// background sync will retry) or [SyncStatus.synced] (uploaded now).
final class SubmissionAccepted extends SubmissionResult {
  const SubmissionAccepted(super.status)
      : assert(
          status == SyncStatus.pending || status == SyncStatus.synced,
          'Accepted submissions are pending or synced, never $status',
        );
}

/// The submission was refused terminally and will not be retried.
///
/// [status] is either [SyncStatus.rejected] (429 rate limit — the visitor
/// must wait, §7) or [SyncStatus.failedPermanent] (400 malformed — a bug).
final class SubmissionRefused extends SubmissionResult {
  const SubmissionRefused(super.status, this.reason)
      : assert(
          status == SyncStatus.rejected ||
              status == SyncStatus.failedPermanent,
          'Refused submissions are rejected or failedPermanent, never '
          '$status',
        );

  /// Human-readable, log-safe reason (no PII).
  final String reason;
}
