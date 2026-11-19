import 'package:ucstgo_showcase_flutter_app/models/remote_outcome.dart';
import 'package:ucstgo_showcase_flutter_app/models/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/models/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/models/queued_rating.dart';
import 'package:ucstgo_showcase_flutter_app/models/rating.dart';
import 'package:ucstgo_showcase_flutter_app/repositories/rating_repository.dart';

import './rating_local_datasource.dart';
import './rating_remote_datasource.dart';
import './rating_model.dart';

/// Local-first rating orchestration (§6.4, §6.6).
///
/// Same contract as feedback: durable write first, best-effort upload, and
/// the visitor's success never depends on the network.
class RatingRepositoryImpl implements RatingRepository {
  RatingRepositoryImpl({
    required this.local,
    required this.remote,
    required this.isOnline,
  });

  final RatingLocalDataSource local;
  final RatingRemoteDataSource remote;
  final Future<bool> Function() isOnline;

  @override
  Future<SubmissionResult> submit(Rating rating) async {
    // 1. Durable row before any network work (Patch D offline rule).
    await local.insert(rating);

    if (!await isOnline()) {
      return const SubmissionAccepted(SyncStatus.pending);
    }

    final RemoteOutcome outcome;
    try {
      outcome = await remote.submit(RatingModel.fromRating(rating));
    } catch (_) {
      return const SubmissionAccepted(SyncStatus.pending);
    }

    switch (outcome) {
      case RemoteOutcome.success:
        await local.markSynced(rating.clientId);
        return const SubmissionAccepted(SyncStatus.synced);

      case RemoteOutcome.rejected:
        await local.markRejected(rating.clientId);
        return const SubmissionRefused(
          SyncStatus.rejected,
          'rate limited by the server',
        );

      case RemoteOutcome.invalid:
        await local.markFailedPermanent(rating.clientId);
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
  Future<List<QueuedRating>> pending({int limit = 50}) =>
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
