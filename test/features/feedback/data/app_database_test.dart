import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/data/local/app_database.dart';

/// Iteration 9 — Drift queue durability (PROJECT_PROCESS.md §6.4, §6.6).
///
/// Proves the local queue is a real database, not a list in memory:
/// both tables round-trip, the idempotency key is enforced by the primary
/// key, timestamps stay UTC, and the pending filter matches the sync
/// vocabulary exactly.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  final createdAt = DateTime.utc(2026, 11, 18, 12, 30);

  PendingFeedbackCompanion feedback({
    String clientId = 'client-0001',
    String? status,
    DateTime? at,
  }) {
    return PendingFeedbackCompanion.insert(
      clientId: clientId,
      deviceId: 'device-0001',
      emojiChoice: 'satisfied',
      createdAt: at ?? createdAt,
      syncStatus: Value(status ?? SyncStatus.pending.wireValue),
    );
  }

  PendingRatingsCompanion rating({
    String clientId = 'rating-0001',
    String? status,
  }) {
    return PendingRatingsCompanion.insert(
      clientId: clientId,
      deviceId: 'device-0001',
      projectId: 'project-01',
      score: 5,
      createdAt: createdAt,
      syncStatus: Value(status ?? SyncStatus.pending.wireValue),
    );
  }

  group('AppDatabase (§6.4, §6.6)', () {
    test('schema version is 1', () {
      expect(db.schemaVersion, 1);
    });

    test('feedback row round-trips with UTC timestamps', () async {
      await db.into(db.pendingFeedback).insert(feedback());

      final rows = await db.select(db.pendingFeedback).get();
      final row = rows.single;

      expect(rows, hasLength(1));
      expect(row.clientId, 'client-0001');
      expect(row.deviceId, 'device-0001');
      expect(row.emojiChoice, 'satisfied');
      expect(row.createdAt, createdAt);
      expect(row.createdAt.isUtc, isTrue, reason: 'UTC must survive storage');
      expect(row.syncStatus, SyncStatus.pending.wireValue);
      expect(row.attempts, 0);
      expect(row.lastAttemptAt, isNull);
      expect(row.nextRetryAt, isNull);
    });

    test('rating row round-trips on the same database', () async {
      await db.into(db.pendingRatings).insert(rating());

      final row = (await db.select(db.pendingRatings).get()).single;

      expect(row.projectId, 'project-01');
      expect(row.score, 5);
      expect(row.syncStatus, SyncStatus.pending.wireValue);
      expect(row.createdAt.isUtc, isTrue);
    });

    test('duplicate client_id is rejected by the primary key', () async {
      await db.into(db.pendingFeedback).insert(feedback());

      await expectLater(
        db.into(db.pendingFeedback).insert(feedback()),
        throwsA(
          predicate(
            (Object error) =>
                error.toString().contains('UNIQUE constraint failed'),
            'a UNIQUE constraint violation',
          ),
        ),
      );

      expect(await db.select(db.pendingFeedback).get(), hasLength(1));
    });

    test('pending filter returns only rows awaiting upload', () async {
      await db.into(db.pendingFeedback).insert(feedback(clientId: 'pending-1'));
      await db.into(db.pendingFeedback).insert(
            feedback(
              clientId: 'synced-1',
              status: SyncStatus.synced.wireValue,
            ),
          );
      await db.into(db.pendingFeedback).insert(
            feedback(
              clientId: 'rejected-1',
              status: SyncStatus.rejected.wireValue,
            ),
          );
      await db.into(db.pendingFeedback).insert(
            feedback(
              clientId: 'failed-1',
              status: SyncStatus.failedPermanent.wireValue,
            ),
          );

      final query = db.select(db.pendingFeedback)
        ..where((table) => table.syncStatus.equals(SyncStatus.pending.wireValue));
      final pending = await query.get();

      expect(pending.map((row) => row.clientId), ['pending-1']);
    });

    test('attempt bookkeeping fields persist', () async {
      await db.into(db.pendingFeedback).insert(feedback());

      final retryAt = createdAt.add(const Duration(seconds: 8));
      await (db.update(db.pendingFeedback)
            ..where((table) => table.clientId.equals('client-0001')))
          .write(
        PendingFeedbackCompanion(
          attempts: const Value(2),
          lastAttemptAt: Value(createdAt),
          nextRetryAt: Value(retryAt),
        ),
      );

      final row = (await db.select(db.pendingFeedback).get()).single;

      expect(row.attempts, 2);
      expect(row.lastAttemptAt, createdAt);
      expect(row.nextRetryAt, retryAt);
    });
  });
}
