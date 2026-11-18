import 'package:drift/drift.dart';

import '../../../../core/domain/sync_status.dart';
import '../../domain/entities/emoji_choice.dart';
import '../../domain/entities/feedback.dart';
import '../../domain/entities/queued_feedback.dart';
import '../local/app_database.dart';

/// Typed CRUD over the durable feedback queue — PROJECT_PROCESS.md §6.4, §6.6.
///
/// This is the only place that maps [Feedback] entities to Drift rows. It
/// deliberately knows nothing about HTTP, Supabase or connectivity: the
/// repository (Iteration 11) orchestrates, the sync engine (Iteration 16)
/// walks the queue through [pending] + [applySyncStatus].
class FeedbackLocalDataSource {
  FeedbackLocalDataSource(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AppDatabase _db;

  /// Injectable clock so retry-deadline behavior is tested without waiting.
  final DateTime Function() _now;

  /// Persists a submission as `pending`, durably, before any network call.
  ///
  /// A duplicate [Feedback.clientId] is a bug (the idempotency key must be
  /// fresh per visitor action) and is rejected by the primary key.
  Future<void> insert(Feedback feedback) async {
    await _db.into(_db.pendingFeedback).insert(
          PendingFeedbackCompanion.insert(
            clientId: feedback.clientId,
            deviceId: feedback.deviceId,
            emojiChoice: feedback.emojiChoice.wireValue,
            createdAt: feedback.createdAt.toUtc(),
          ),
        );
  }

  /// Rows eligible for upload, FIFO by `createdAt`.
  ///
  /// "Eligible" means `pending` **and** past the backoff deadline: a row
  /// waiting for its next retry is not offered to the sync engine early.
  /// Retry-deadline filtering happens in Dart on purpose — comparing
  /// ISO-8601 text in SQLite is not reliably chronological for
  /// sub-millisecond timestamps, and DateTime comparison here is exact.
  Future<List<QueuedFeedback>> pending({int limit = 50}) async {
    assert(limit > 0, 'limit must be positive');

    final rows = await (_db.select(_db.pendingFeedback)
          ..where(
            (table) =>
                table.syncStatus.equals(SyncStatus.pending.wireValue),
          ))
        .get();

    final now = _now().toUtc();
    final due = rows.where((row) {
      final retryAt = row.nextRetryAt?.toUtc();
      return retryAt == null || !retryAt.isAfter(now);
    }).toList()
      ..sort((a, b) {
        final byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.clientId.compareTo(b.clientId);
      });

    return due.take(limit).map(_toQueued).toList();
  }

  /// Live count of rows still awaiting upload — includes rows waiting for
  /// their backoff deadline, unlike [pending].
  Stream<int> watchPendingCount() {
    final count = _db.pendingFeedback.clientId.count();
    final query = _db.selectOnly(_db.pendingFeedback)
      ..addColumns([count])
      ..where(
        _db.pendingFeedback.syncStatus.equals(SyncStatus.pending.wireValue),
      );

    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// Terminal success (200 or replay 409) — §6.6.
  Future<void> markSynced(String clientId) =>
      _setStatus(clientId, SyncStatus.synced);

  /// Rate limited by the server (429) — terminal, never retried.
  Future<void> markRejected(String clientId) =>
      _setStatus(clientId, SyncStatus.rejected);

  /// Malformed payload (400) — terminal, signals a client bug.
  Future<void> markFailedPermanent(String clientId) =>
      _setStatus(clientId, SyncStatus.failedPermanent);

  /// Records a failed attempt and blocks retries until [nextRetryAt].
  ///
  /// Increments [PendingFeedback.attempts] so the backoff policy in
  /// Iteration 16 can cap at six retries.
  Future<void> scheduleRetry(String clientId, DateTime nextRetryAt) async {
    final row = await (_db.select(_db.pendingFeedback)
          ..where((table) => table.clientId.equals(clientId)))
        .getSingle();

    await (_db.update(_db.pendingFeedback)
          ..where((table) => table.clientId.equals(clientId)))
        .write(
      PendingFeedbackCompanion(
        attempts: Value(row.attempts + 1),
        lastAttemptAt: Value(_now().toUtc()),
        nextRetryAt: Value(nextRetryAt.toUtc()),
      ),
    );
  }

  /// Removes a row (after a successful sync, if the queue is trimmed).
  Future<void> delete(String clientId) async {
    await (_db.delete(_db.pendingFeedback)
          ..where((table) => table.clientId.equals(clientId)))
        .go();
  }

  Future<void> _setStatus(String clientId, SyncStatus status) async {
    await (_db.update(_db.pendingFeedback)
          ..where((table) => table.clientId.equals(clientId)))
        .write(
      PendingFeedbackCompanion(
        syncStatus: Value(status.wireValue),
        nextRetryAt: const Value(null),
      ),
    );
  }

  QueuedFeedback _toQueued(PendingFeedbackData row) => QueuedFeedback(
        feedback: _toEntity(row),
        attempts: row.attempts,
      );

  Feedback _toEntity(PendingFeedbackData row) {
    return Feedback(
      clientId: row.clientId,
      deviceId: row.deviceId,
      emojiChoice: EmojiChoice.fromJson(row.emojiChoice),
      createdAt: row.createdAt.toUtc(),
    );
  }
}
