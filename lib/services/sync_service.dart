import '../core/domain/sync_status.dart';
import '../features/feedback/data/datasources/feedback_remote_datasource.dart';
import '../features/feedback/data/models/feedback_model.dart';
import '../features/feedback/domain/entities/feedback.dart';
import '../features/feedback/domain/entities/queued_feedback.dart';
import '../features/feedback/domain/repositories/feedback_repository.dart';

/// The scheduler's view of the sync engine.
abstract interface class SyncRunner {
  /// Drains every due row; concurrent calls coalesce in the implementation.
  Future<void> syncAll();
}

/// Drains the durable queue through the tested remote seam — §6.4/§6.6/§13.
///
/// Design rules:
/// - **Serial:** one upload at a time; a low-end kiosk should never have
///   several requests in flight.
/// - **Batched but complete:** `pending(limit:)` bounds each query, the loop
///   repeats until nothing is due.
/// - **Coalesced:** concurrent [syncAll] calls share one run, so the four
///   triggers landing together (Iteration 17) cannot stampede.
/// - **Durable backoff:** the attempt count comes from the row, not memory,
///   so killing the app does not reset the retry ladder.
class SyncService implements SyncRunner {
  SyncService({
    required this.queue,
    required this.remote,
    DateTime Function()? now,
    this.batchSize = 50,
    this.retryDelays = defaultRetryDelays,
  })  : assert(batchSize > 0, 'batchSize must be positive'),
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

  /// Injectable clock so the backoff ladder is tested instantly.
  final DateTime Function() now;

  /// Maximum rows fetched per query (not per run).
  final int batchSize;

  /// Tunable for tests; defaults to the §13 ladder.
  final List<Duration> retryDelays;

  Future<void>? _inFlight;

  /// Live count of rows awaiting upload, including backoff-waiting rows.
  Stream<int> get pendingCount => queue.watchPendingCount();

  /// Uploads every row that is due, serially.
  ///
  /// Concurrent calls share the same in-flight run; the next call after it
  /// completes starts a fresh sweep.
  @override
  Future<void> syncAll() {
    return _inFlight ??= _drain().whenComplete(() => _inFlight = null);
  }

  Future<void> _drain() async {
    while (true) {
      final batch = await queue.pending(limit: batchSize);
      if (batch.isEmpty) {
        return;
      }
      for (final item in batch) {
        await _syncOne(item);
      }
    }
  }

  Future<void> _syncOne(QueuedFeedback item) async {
    final outcome = await _safeSubmit(item.feedback);

    switch (outcome) {
      case RemoteOutcome.success:
        // 200 or replay 409 — the row is safely on the server.
        await queue.applySyncStatus(item.feedback.clientId, SyncStatus.synced);

      case RemoteOutcome.rejected:
        // 429 — visitor over the limit; never retried.
        await queue.applySyncStatus(item.feedback.clientId, SyncStatus.rejected);

      case RemoteOutcome.invalid:
        // 400 — a client bug; retrying cannot help.
        await queue.applySyncStatus(
          item.feedback.clientId,
          SyncStatus.failedPermanent,
        );

      case RemoteOutcome.serverError:
      case RemoteOutcome.networkFailure:
        await _scheduleRetry(item);
    }
  }

  Future<void> _scheduleRetry(QueuedFeedback item) async {
    if (item.attempts >= retryDelays.length) {
      // Six retries exhausted — stop burning battery on a hopeless row.
      await queue.applySyncStatus(
        item.feedback.clientId,
        SyncStatus.failedPermanent,
      );
      return;
    }

    final delay = retryDelays[item.attempts];
    await queue.applySyncStatus(
      item.feedback.clientId,
      SyncStatus.pending,
      nextRetryAt: now().toUtc().add(delay),
    );
  }

  Future<RemoteOutcome> _safeSubmit(Feedback feedback) async {
    try {
      return await remote.submit(FeedbackModel.fromFeedback(feedback));
    } catch (_) {
      // The seam promises not to throw; stay defensive so a buggy datasource
      // cannot abort the whole sweep.
      return RemoteOutcome.networkFailure;
    }
  }
}
