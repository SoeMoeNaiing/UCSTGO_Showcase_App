import 'package:drift/drift.dart';

import '../models/sync_status.dart';
import '../models/queued_rating.dart';
import '../models/rating.dart';
import '../database/app_database.dart';

/// Typed CRUD over the durable rating queue (§6.4, §6.6).
///
/// Mirrors `FeedbackLocalDataSource`: both tables live in the same
/// `AppDatabase`, share the status vocabulary and use the same backoff
/// semantics. No HTTP or connectivity knowledge here.
class RatingLocalDataSource {
  RatingLocalDataSource(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// Persists a rating as `pending` before any network work.
  Future<void> insert(Rating rating) async {
    await _db.into(_db.pendingRatings).insert(
          PendingRatingsCompanion.insert(
            clientId: rating.clientId,
            deviceId: rating.deviceId,
            projectId: rating.projectId,
            score: rating.score,
            createdAt: rating.createdAt.toUtc(),
          ),
        );
  }

  /// Due rows (`pending` and past their retry deadline), FIFO by time.
  Future<List<QueuedRating>> pending({int limit = 50}) async {
    assert(limit > 0, 'limit must be positive');

    final rows = await (_db.select(_db.pendingRatings)
          ..where((table) =>
              table.syncStatus.equals(SyncStatus.pending.wireValue)))
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

  /// Live count of all pending rows, including backoff-waiting ones.
  Stream<int> watchPendingCount() {
    final count = _db.pendingRatings.clientId.count();
    final query = _db.selectOnly(_db.pendingRatings)
      ..addColumns([count])
      ..where(
        _db.pendingRatings.syncStatus.equals(SyncStatus.pending.wireValue),
      );
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<void> markSynced(String clientId) =>
      _setStatus(clientId, SyncStatus.synced);

  Future<void> markRejected(String clientId) =>
      _setStatus(clientId, SyncStatus.rejected);

  Future<void> markFailedPermanent(String clientId) =>
      _setStatus(clientId, SyncStatus.failedPermanent);

  /// Records a failed attempt and blocks retries until [nextRetryAt].
  Future<void> scheduleRetry(String clientId, DateTime nextRetryAt) async {
    final row = await (_db.select(_db.pendingRatings)
          ..where((table) => table.clientId.equals(clientId)))
        .getSingle();

    await (_db.update(_db.pendingRatings)
          ..where((table) => table.clientId.equals(clientId)))
        .write(
      PendingRatingsCompanion(
        attempts: Value(row.attempts + 1),
        lastAttemptAt: Value(_now().toUtc()),
        nextRetryAt: Value(nextRetryAt.toUtc()),
      ),
    );
  }

  Future<void> delete(String clientId) async {
    await (_db.delete(_db.pendingRatings)
          ..where((table) => table.clientId.equals(clientId)))
        .go();
  }

  Future<void> _setStatus(String clientId, SyncStatus status) async {
    await (_db.update(_db.pendingRatings)
          ..where((table) => table.clientId.equals(clientId)))
        .write(
      PendingRatingsCompanion(
        syncStatus: Value(status.wireValue),
        nextRetryAt: const Value(null),
      ),
    );
  }

  QueuedRating _toQueued(PendingRating row) => QueuedRating(
        rating: Rating(
          clientId: row.clientId,
          deviceId: row.deviceId,
          projectId: row.projectId,
          score: row.score,
          createdAt: row.createdAt.toUtc(),
        ),
        attempts: row.attempts,
      );
}
