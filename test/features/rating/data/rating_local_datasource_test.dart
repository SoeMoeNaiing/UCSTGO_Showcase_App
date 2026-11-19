import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/data/local/app_database.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/data/datasources/rating_local_datasource.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/entities/rating.dart';

/// Iteration 28 — RatingLocalDataSource gate (§6.4, §6.6).
///
/// The ratings queue uses the same durable semantics as feedback: FIFO due
/// rows, backoff deadlines, attempt bookkeeping and live counts.
void main() {
  late AppDatabase db;
  late RatingLocalDataSource local;
  late DateTime now;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 19, 12);
    local = RatingLocalDataSource(db, now: () => now);
  });

  tearDown(() async => db.close());

  Rating build({
    String client = 'client-1',
    DateTime? at,
    int score = 4,
  }) =>
      Rating(
        clientId: client,
        deviceId: 'device-1',
        projectId: 'campus-navigator',
        score: score,
        createdAt: at ?? now,
      );

  group('RatingLocalDataSource (§6.4, §6.6)', () {
    test('insert makes a row immediately pending', () async {
      final rating = build();
      await local.insert(rating);

      final pending = await local.pending();
      expect(pending.single.rating, rating);
      expect(pending.single.attempts, 0);

      final row = (db.select(db.pendingRatings)
            ..where((table) => table.clientId.equals(rating.clientId)))
          .getSingle();
      expect((await row).syncStatus, SyncStatus.pending.wireValue);
    });

    test('pending is FIFO, honours the limit and respects retry deadlines',
        () async {
      await local.insert(
        build(client: 'third', at: now.add(const Duration(minutes: 2))),
      );
      await local.insert(build(client: 'first', at: now));
      await local.insert(
        build(client: 'second', at: now.add(const Duration(minutes: 1))),
      );

      expect(
        (await local.pending(limit: 2)).map((row) => row.rating.clientId),
        ['first', 'second'],
      );

      await local.scheduleRetry(
        'first',
        now.add(const Duration(seconds: 2)),
      );
      expect(
        (await local.pending()).map((row) => row.rating.clientId),
        ['second', 'third'],
        reason: 'a backoff-waiting row is not due yet',
      );

      now = now.add(const Duration(seconds: 2));
      expect(
        (await local.pending()).map((row) => row.rating.clientId),
        ['first', 'second', 'third'],
      );
    });

    test('status transitions and retry bookkeeping', () async {
      final rating = build();
      await local.insert(rating);

      await local.scheduleRetry(rating.clientId, now.add(const Duration(seconds: 4)));
      final afterRetry = await local.pending();
      expect(afterRetry, isEmpty, reason: 'deadline is in the future');

      await local.markRejected(rating.clientId);
      final row = (db.select(db.pendingRatings)
            ..where((table) => table.clientId.equals(rating.clientId)))
          .getSingle();
      final stored = await row;
      expect(stored.syncStatus, SyncStatus.rejected.wireValue);
      expect(stored.attempts, 1);
      expect(stored.nextRetryAt, isNull);
    });

    test('watchPendingCount follows all pending rows', () async {
      await local.insert(build(client: 'a'));
      await local.insert(build(client: 'b'));

      final counts = <int>[];
      final subscription = local.watchPendingCount().listen(counts.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(counts.last, 2);

      await local.markSynced('a');
      await pumpEventQueue();
      expect(counts.last, 1);
    });
  });
}
