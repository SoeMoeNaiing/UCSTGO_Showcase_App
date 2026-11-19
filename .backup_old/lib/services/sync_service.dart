import '../models/sync_status.dart';
import '../repositories/feedback_remote_datasource.dart';
import '../repositories/feedback_model.dart';
import '../models/queued_feedback.dart';
import '../repositories/feedback_repository.dart';
import '../repositories/rating_remote_datasource.dart';
import '../repositories/rating_model.dart';
import '../models/queued_rating.dart';
import '../repositories/rating_repository.dart';

/// The scheduler's view of the sync engine.
abstract interface class SyncRunner {
  /// Drains every due row; concurrent calls coalesce in the implementation.
  Future<void> syncAll();
}

/// Drains the durable queues through the tested remote seams — §6.4/§6.6/§13.
///
/// Design rules:
/// - **Serial:** one upload at a time; a low-end kiosk should never have
///   several requests in flight.
/// - **Both queues:** feedback first, then ratings, in one coalesced sweep
///   (I28). The rating seams are optional so the I16 tests still compile.
/// - **Batched but complete:** `pending(limit:)` bounds each query; the loop
///   repeats until nothing is due.
/// - **Coalesced:** concurrent [syncAll] calls share one run.
/// - **Durable backoff:** attempt counts come from the rows, not memory, so
///   killing the app does not reset the retry ladder.
class SyncService implements SyncRunner {
  SyncService({
    required this.queue,
    required this.remote,
    this.ratingQueue,
    this.ratingRemote,
    DateTime Function()? now,
    this.batchSize = 50,
    this.retryDelays = defaultRetryDelays,
  }) : assert(batchSize > 0, 'batchSize must be positive'),
       now = now ?? DateTime.now;

  /// §13: 2 → 4 → 8 → 16 → 32 → 60s, then terminal.
  static const defaultRetryDelays = <Duration>[
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
    Duration(seconds: 32),
    Duration(seconds: 60),
  ];

  final FeedbackRepository queue;
  final FeedbackRemoteDataSource remote;

  /// Rating queue/remote — both must be supplied to drain ratings (I28).
  final RatingRepository? ratingQueue;
  final RatingRemoteDataSource? ratingRemote;

  final DateTime Function() now;
  final int batchSize;
  final List<Duration> retryDelays;

  Future<void>? _inFlight;

  /// Live feedback count, including backoff-waiting rows.
  Stream<int> get pendingCount => queue.watchPendingCount();

  @override
  Future<void> syncAll() {
    return _inFlight ??= _drain().whenComplete(() => _inFlight = null);
  }

  Future<void> _drain() async {
    await _drainQueue(
      load: () => queue.pending(limit: batchSize),
      handle: _syncFeedback,
    );

    final ratings = ratingQueue;
    final ratingUpload = ratingRemote;
    if (ratings != null && ratingUpload != null) {
      await _drainQueue(
        load: () => ratings.pending(limit: batchSize),
        handle: _syncRating,
      );
    }
  }

  Future<void> _drainQueue<T>({
    required Future<List<T>> Function() load,
    required Future<void> Function(T) handle,
  }) async {
    while (true) {
      final batch = await load();
      if (batch.isEmpty) {
        return;
      }
      for (final item in batch) {
        await handle(item);
      }
    }
  }

  Future<void> _syncFeedback(QueuedFeedback item) => _submitAndApply(
    clientId: item.feedback.clientId,
    attempts: item.attempts,
    submit: () => remote.submit(FeedbackModel.fromFeedback(item.feedback)),
    apply: (status, {nextRetryAt}) => queue.applySyncStatus(
      item.feedback.clientId,
      status,
      nextRetryAt: nextRetryAt,
    ),
  );

  Future<void> _syncRating(QueuedRating item) => _submitAndApply(
    clientId: item.rating.clientId,
    attempts: item.attempts,
    submit: () => ratingRemote!.submit(RatingModel.fromRating(item.rating)),
    apply: (status, {nextRetryAt}) => ratingQueue!.applySyncStatus(
      item.rating.clientId,
      status,
      nextRetryAt: nextRetryAt,
    ),
  );

  /// One item's §6.6 outcome matrix + §13 backoff, shared by both queues.
  Future<void> _submitAndApply({
    required String clientId,
    required int attempts,
    required Future<RemoteOutcome> Function() submit,
    required Future<void> Function(SyncStatus status, {DateTime? nextRetryAt})
    apply,
  }) async {
    final outcome = await _safeSubmit(submit);

    switch (outcome) {
      case RemoteOutcome.success:
        await apply(SyncStatus.synced);

      case RemoteOutcome.rejected:
        await apply(SyncStatus.rejected);

      case RemoteOutcome.invalid:
        await apply(SyncStatus.failedPermanent);

      case RemoteOutcome.serverError:
      case RemoteOutcome.networkFailure:
        if (attempts >= retryDelays.length) {
          // Six retries exhausted — stop burning battery on a hopeless row.
          await apply(SyncStatus.failedPermanent);
          return;
        }
        await apply(
          SyncStatus.pending,
          nextRetryAt: now().toUtc().add(retryDelays[attempts]),
        );
    }
  }

  Future<RemoteOutcome> _safeSubmit(
    Future<RemoteOutcome> Function() submit,
  ) async {
    try {
      return await submit();
    } catch (_) {
      // A buggy datasource cannot abort the whole sweep.
      return RemoteOutcome.networkFailure;
    }
  }
}
