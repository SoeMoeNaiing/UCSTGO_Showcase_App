import '../../../../core/domain/submission_result.dart';
import '../../../../core/domain/sync_status.dart';
import '../../domain/entities/feedback.dart';
import '../../domain/entities/queued_feedback.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../datasources/feedback_local_datasource.dart';
import '../datasources/feedback_remote_datasource.dart';
import '../models/feedback_model.dart';

/// Local-first orchestration — PROJECT_PROCESS.md §6.4, §6.6.
///
/// The contract in one sentence: **the submission is durable before any
/// network work starts, and a network problem never fails the visitor's
/// action.** Only a definitive server refusal (429 / 400) is surfaced,
/// and even those rows stay in the queue with a terminal status.
class FeedbackRepositoryImpl implements FeedbackRepository {
  FeedbackRepositoryImpl({
    required this.local,
    required this.remote,
    required this.isOnline,
  });

  final FeedbackLocalDataSource local;
  final FeedbackRemoteDataSource remote;

  /// Injected connectivity check; Phase 2 wires `ConnectivityService`
  /// here, tests inject a fake.
  final Future<bool> Function() isOnline;

  @override
  Future<SubmissionResult> submit(Feedback feedback) async {
    // 1. Durable write first — the queue is the source of truth (§6.4).
    await local.insert(feedback);

    // 2. Best-effort upload, only when connectivity is believed usable.
    if (!await isOnline()) {
      return const SubmissionAccepted(SyncStatus.pending);
    }

    final RemoteOutcome outcome;
    try {
      // The seam takes the exact §6.2 wire DTO, so Phase 6 cannot bypass
      // the payload contract.
      outcome = await remote.submit(FeedbackModel.fromFeedback(feedback));
    } catch (_) {
      // The seam promises not to throw; stay defensive so a buggy
      // datasource can never break the visitor's thank-you.
      return const SubmissionAccepted(SyncStatus.pending);
    }

    switch (outcome) {
      case RemoteOutcome.success:
        await local.markSynced(feedback.clientId);
        return const SubmissionAccepted(SyncStatus.synced);

      case RemoteOutcome.rejected:
        await local.markRejected(feedback.clientId);
        return const SubmissionRefused(
          SyncStatus.rejected,
          'rate limited by the server',
        );

      case RemoteOutcome.invalid:
        await local.markFailedPermanent(feedback.clientId);
        return const SubmissionRefused(
          SyncStatus.failedPermanent,
          'payload rejected by the server',
        );

      case RemoteOutcome.serverError:
      case RemoteOutcome.networkFailure:
        // Row stays pending; SyncService retries with backoff (§6.6).
        return const SubmissionAccepted(SyncStatus.pending);
    }
  }

  @override
  Future<List<QueuedFeedback>> pending({int limit = 50}) =>
      local.pending(limit: limit);

  @override
  Stream<int> watchPendingCount() => local.watchPendingCount();

  @override
  Future<void> applySyncStatus(
    String clientId,
    SyncStatus status, {
    DateTime? nextRetryAt,
  }) async {
    switch (status) {
      case SyncStatus.synced:
        await local.markSynced(clientId);
      case SyncStatus.rejected:
        await local.markRejected(clientId);
      case SyncStatus.failedPermanent:
        await local.markFailedPermanent(clientId);
      case SyncStatus.pending:
        if (nextRetryAt != null) {
          await local.scheduleRetry(clientId, nextRetryAt);
        }
    }
  }
}
